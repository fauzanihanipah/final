#!/usr/bin/env bash
# ============================================================
#  Aggressive cleanup of leftovers from previous VPN panel
#  scripts that commonly squat on the same ports DEWA needs
#  (80, 443, 445, 777, 8880). Runs BEFORE the service install
#  loop so nginx/stunnel/wsproxy can bind cleanly.
# ============================================================

# Names of legacy systemd units known to be installed by other panel
# scripts (Vinaa, Singgih, Khaeerul, KhansVPN, etc). We stop+disable+mask
# all of them; missing units are silently ignored.
DEWA_LEGACY_UNITS=(
    apache2 httpd lighttpd caddy
    ssh-ws ssh-ws-noTLS ssh-ws-tls ssh-ws-py
    ws-stunnel ws-dropbear ws-openssh
    ohp openssh-ohp openssh-https
    trojan-go trojan-server
    cloud-server vless-server vmess-server
    openvpn@server openvpn-server@server pptpd xl2tpd
    sslh stunnel stunnel4
    runn run server-vpn vpn-server
)

# Ports our managed services need exclusive access to, with the
# command-name (from /proc/<pid>/comm) we expect to own them. Anything
# else on these ports gets killed.
declare -A DEWA_RESERVED_PORTS=(
    [80]="nginx"
    [443]="nginx"
    [445]="stunnel|stunnel4"
    [777]="stunnel|stunnel4"
    [8880]="websocat"
)

dewa_cleanup_legacy() {
    inst_log "=== CLEANUP / PORT FREE ==="

    # ---- Stop + disable + mask known legacy units ------------------
    local u
    for u in "${DEWA_LEGACY_UNITS[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${u}\.service"; then
            inst_log "disabling legacy unit: ${u}"
            inst_run systemctl stop    "$u"
            inst_run systemctl disable "$u"
        fi
    done

    # ---- Kill processes on reserved ports that aren't ours ---------
    if ! command -v ss >/dev/null 2>&1; then
        inst_pkg_install iproute2 || true
    fi
    local port expected pid_list pid name kill_attempts
    for port in "${!DEWA_RESERVED_PORTS[@]}"; do
        expected="${DEWA_RESERVED_PORTS[$port]}"
        # Loop a few times because a parent process may respawn a child.
        for kill_attempts in 1 2 3; do
            pid_list=$(ss -tlnp 2>/dev/null \
                | awk -v p=":${port}\$" '$4 ~ p' \
                | grep -oE 'pid=[0-9]+' \
                | cut -d= -f2 | sort -u)
            [[ -z "$pid_list" ]] && break
            for pid in $pid_list; do
                [[ -z "$pid" ]] && continue
                name=$(cat "/proc/${pid}/comm" 2>/dev/null | head -1 | tr -d '\0')
                # Skip if it's already the right process.
                if [[ "$name" =~ ^(${expected})$ ]]; then
                    continue
                fi
                inst_log "  port ${port}: killing leftover '${name:-?}' pid=${pid}"
                kill -TERM "$pid" 2>/dev/null
                sleep 1
                if [[ -d "/proc/${pid}" ]]; then
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            done
            sleep 1
        done

        # Final check.
        pid_list=$(ss -tlnp 2>/dev/null | awk -v p=":${port}\$" '$4 ~ p' | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u)
        if [[ -n "$pid_list" ]]; then
            for pid in $pid_list; do
                name=$(cat "/proc/${pid}/comm" 2>/dev/null | head -1)
                if ! [[ "$name" =~ ^(${expected})$ ]]; then
                    inst_log "  WARN: port ${port} still occupied by '${name:-?}' pid=${pid}"
                fi
            done
        fi
    done

    inst_run systemctl daemon-reload

    # ---- Final fallback: fuser -k -----------------------------------
    # If a reserved port is STILL occupied after three SIGKILL rounds,
    # use fuser to nuke whatever still has it open (file descriptor or
    # process). This catches systemd services with Restart=always that
    # respawn faster than our loop.
    if command -v fuser >/dev/null 2>&1; then
        for port in "${!DEWA_RESERVED_PORTS[@]}"; do
            if ss -tln 2>/dev/null | awk -v p=":${port}\$" '$4 ~ p {found=1} END{exit !found}'; then
                inst_log "  port ${port}: fuser -k fallback"
                fuser -k -TERM "${port}/tcp" 2>/dev/null || true
                sleep 1
                fuser -k -KILL "${port}/tcp" 2>/dev/null || true
            fi
        done
    fi
    return 0
}

# Allow running as a stand-alone CLI ("dewa-cleanup").
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    [[ -f /opt/dewa-panel/install/common.sh ]] && source /opt/dewa-panel/install/common.sh
    [[ -f /opt/dewa-panel/menu/lib/ui.sh   ]] && source /opt/dewa-panel/menu/lib/ui.sh
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        echo "dewa-cleanup must run as root." >&2
        exit 1
    fi
    if declare -F ui_card_top >/dev/null 2>&1; then
        ui_clear
        ui_header "DEWA CLEANUP" "Free reserved ports + disable legacy units"
        ui_blank
    fi
    dewa_cleanup_legacy
    if declare -F ui_notify_success >/dev/null 2>&1; then
        ui_notify_success "Cleanup complete. Re-run 'update-panel' to install fresh."
    else
        echo "Cleanup complete. Re-run 'update-panel'."
    fi
fi
