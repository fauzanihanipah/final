#!/usr/bin/env bash
# ============================================================
#  DEWA TUNNELING PANEL — System Information Helpers
#  ----------------------------------------------------------
#  Pure data-gathering layer. No printing, no UI. Every helper
#  returns a string on stdout and never errors out — values
#  fall back to sensible placeholders when a source is missing
#  (e.g. running on a workstation or fresh install).
# ============================================================

[[ -n "${__DEWA_SYSINFO_LOADED:-}" ]] && return 0
__DEWA_SYSINFO_LOADED=1

# ------------------------------------------------------------
#  Small helpers
# ------------------------------------------------------------
__si_first_line() { head -n1 2>/dev/null || true; }
__si_trim()       { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
__si_have()       { command -v "$1" >/dev/null 2>&1; }

# Read first non-empty line of a file if it exists, else echo $2 (default).
__si_read() {
    local f="$1" def="${2:-}"
    if [[ -r "$f" ]]; then
        local v
        v=$(grep -m1 -v '^[[:space:]]*$' "$f" 2>/dev/null | __si_trim)
        [[ -n "$v" ]] && { printf '%s' "$v"; return; }
    fi
    printf '%s' "$def"
}

# ------------------------------------------------------------
#  VPS information
# ------------------------------------------------------------
sys_hostname() {
    hostname 2>/dev/null || __si_read /etc/hostname "unknown"
}

sys_domain() {
    # Common convention used by VPN panels — first match wins.
    local candidates=(
        /etc/xray/domain
        /etc/v2ray/domain
        /root/domain
        /etc/domain
        /usr/local/etc/xray/domain
    )
    local f
    for f in "${candidates[@]}"; do
        local v
        v=$(__si_read "$f" "")
        [[ -n "$v" ]] && { printf '%s' "$v"; return; }
    done
    printf '%s' "not-configured"
}

sys_os() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        ( . /etc/os-release; printf '%s' "${PRETTY_NAME:-${NAME:-Linux} ${VERSION_ID:-}}" )
        return
    fi
    if __si_have lsb_release; then
        lsb_release -ds 2>/dev/null && return
    fi
    uname -s 2>/dev/null || printf 'Unknown'
}

sys_kernel() { uname -r 2>/dev/null || printf 'unknown'; }

sys_arch() { uname -m 2>/dev/null || printf 'unknown'; }

sys_uptime() {
    if __si_have uptime; then
        local u
        u=$(uptime -p 2>/dev/null | sed 's/^up //')
        [[ -n "$u" ]] && { printf '%s' "$u"; return; }
    fi
    if [[ -r /proc/uptime ]]; then
        local secs days hours mins
        secs=$(awk '{print int($1)}' /proc/uptime)
        days=$(( secs / 86400 ))
        hours=$(( (secs % 86400) / 3600 ))
        mins=$(( (secs % 3600) / 60 ))
        if (( days > 0 )); then
            printf '%d Days, %d Hours' "$days" "$hours"
        else
            printf '%d Hours, %d Minutes' "$hours" "$mins"
        fi
        return
    fi
    printf 'unknown'
}

sys_ip() {
    # Try public IP via curl (typical on a VPS), fall back to first non-loopback.
    local ip=""
    if __si_have curl; then
        ip=$(curl -fsS --max-time 3 ifconfig.me 2>/dev/null \
          || curl -fsS --max-time 3 ipinfo.io/ip 2>/dev/null \
          || curl -fsS --max-time 3 api.ipify.org 2>/dev/null)
    fi
    if [[ -z "$ip" ]] && __si_have hostname; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [[ -z "$ip" ]] && __si_have ip; then
        ip=$(ip -4 -o addr show scope global 2>/dev/null \
            | awk '{print $4}' | cut -d/ -f1 | head -n1)
    fi
    [[ -z "$ip" ]] && ip="x.x.x.x"
    printf '%s' "$ip"
}

sys_isp() {
    if __si_have curl; then
        local org
        org=$(curl -fsS --max-time 3 ipinfo.io/org 2>/dev/null)
        [[ -n "$org" ]] && { printf '%s' "$org"; return; }
    fi
    printf 'unknown'
}

sys_timezone() {
    if [[ -r /etc/timezone ]]; then
        __si_read /etc/timezone "UTC"; return
    fi
    if __si_have timedatectl; then
        timedatectl show -p Timezone --value 2>/dev/null && return
    fi
    date '+%Z' 2>/dev/null || printf 'UTC'
}

sys_date() { date '+%a, %d %b %Y  %H:%M:%S %Z' 2>/dev/null || printf 'unknown'; }

# ------------------------------------------------------------
#  Resource usage (returns integer percent or rounded value)
# ------------------------------------------------------------
sys_cpu_usage() {
    # Sample /proc/stat twice to compute CPU usage over a short window.
    if [[ -r /proc/stat ]]; then
        local a b
        a=$(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat)
        sleep 0.2
        b=$(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8}' /proc/stat)
        # shellcheck disable=SC2206
        local A=($a) B=($b)
        local idle_a=$(( A[3] + A[4] ))
        local idle_b=$(( B[3] + B[4] ))
        local total_a=0 total_b=0 i
        for i in 0 1 2 3 4 5 6; do
            total_a=$(( total_a + A[i] ))
            total_b=$(( total_b + B[i] ))
        done
        local total_d=$(( total_b - total_a ))
        local idle_d=$(( idle_b - idle_a ))
        if (( total_d > 0 )); then
            local used=$(( (total_d - idle_d) * 100 / total_d ))
            (( used < 0 )) && used=0
            (( used > 100 )) && used=100
            printf '%d' "$used"
            return
        fi
    fi
    printf '0'
}

sys_ram_usage() {
    if [[ -r /proc/meminfo ]]; then
        local total avail
        total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
        avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
        if [[ -n "$total" && -n "$avail" && "$total" -gt 0 ]]; then
            printf '%d' $(( (total - avail) * 100 / total ))
            return
        fi
    fi
    printf '0'
}

sys_disk_usage() {
    local mount="${1:-/}"
    if __si_have df; then
        df -P "$mount" 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}' | head -n1
        return
    fi
    printf '0'
}

sys_ram_human() {
    if [[ -r /proc/meminfo ]]; then
        local total used
        total=$(awk '/^MemTotal:/{printf "%.1f", $2/1024/1024}' /proc/meminfo)
        local avail
        avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
        local total_kb
        total_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
        if [[ -n "$total_kb" && -n "$avail" ]]; then
            used=$(awk -v t="$total_kb" -v a="$avail" 'BEGIN{printf "%.1f", (t-a)/1024/1024}')
            printf '%s GB / %s GB' "$used" "$total"
            return
        fi
    fi
    printf 'unknown'
}

sys_disk_human() {
    local mount="${1:-/}"
    if __si_have df; then
        df -h "$mount" 2>/dev/null | awk 'NR==2 {printf "%s / %s", $3, $2}'
        return
    fi
    printf 'unknown'
}

sys_load_avg() {
    if [[ -r /proc/loadavg ]]; then
        awk '{printf "%s, %s, %s", $1, $2, $3}' /proc/loadavg
        return
    fi
    printf 'unknown'
}

# Network condition heuristic — checks reachability of well-known hosts.
sys_network_status() {
    if __si_have ping; then
        if ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; then
            printf 'NORMAL'
            return
        fi
        if ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
            printf 'SLOW'
            return
        fi
        printf 'OFFLINE'
        return
    fi
    printf 'UNKNOWN'
}

# ------------------------------------------------------------
#  Service status — returns ACTIVE / OFFLINE / WARNING
# ------------------------------------------------------------
sys_service_status() {
    local name="$1"
    if __si_have systemctl; then
        local state
        state=$(systemctl is-active "$name" 2>/dev/null || true)
        case "$state" in
            active)        printf 'ACTIVE'  ;;
            activating|reloading) printf 'WARNING' ;;
            inactive|failed|unknown|dead) printf 'OFFLINE' ;;
            *)             printf 'OFFLINE' ;;
        esac
        return
    fi
    if __si_have service; then
        if service "$name" status >/dev/null 2>&1; then printf 'ACTIVE'
        else printf 'OFFLINE'; fi
        return
    fi
    if pgrep -x "$name" >/dev/null 2>&1; then printf 'ACTIVE'
    else printf 'OFFLINE'; fi
}

# Standard service list rendered in the dashboard.
SYS_SERVICES=(SSH DROPBEAR STUNNEL5 XRAY NGINX BADVPN SLOWDNS FAIL2BAN)

# Lookup a unit name from a label.
sys_service_unit() {
    case "$1" in
        SSH)
            # Debian/Ubuntu use 'ssh', RHEL family uses 'sshd'.
            if systemctl list-unit-files 2>/dev/null | grep -q '^ssh\.service'; then
                echo ssh
            elif systemctl list-unit-files 2>/dev/null | grep -q '^sshd\.service'; then
                echo sshd
            else
                echo ssh
            fi
            ;;
        DROPBEAR)  echo dropbear ;;
        STUNNEL5)
            # The installer ships a 'dewa-stunnel.service' (preferred);
            # 'stunnel5' is kept as a compat alias. Fall back to the distro
            # unit names if neither is installed yet.
            if systemctl list-unit-files 2>/dev/null | grep -q '^dewa-stunnel\.service'; then
                echo dewa-stunnel
            elif systemctl list-unit-files 2>/dev/null | grep -q '^stunnel5\.service'; then
                echo stunnel5
            elif systemctl list-unit-files 2>/dev/null | grep -q '^stunnel4\.service'; then
                echo stunnel4
            else
                echo stunnel
            fi
            ;;
        XRAY)      echo xray ;;
        NGINX)     echo nginx ;;
        BADVPN)    echo badvpn ;;
        SLOWDNS)   echo slowdns ;;
        FAIL2BAN)  echo fail2ban ;;
        *)         echo "$1" ;;
    esac
}

# ------------------------------------------------------------
#  Port information — read from config files when present, else
#  show conventional defaults so the card never looks empty.
# ------------------------------------------------------------
__si_ports_default() {
    # These reflect the actual ports opened by the install/ scripts.
    # Update both sides together when changing ports.
    case "$1" in
        SSH_TCP)      echo "22, 444" ;;
        SSH_SSL)      echo "445, 777" ;;
        SSH_WS_TLS)   echo "443" ;;
        SSH_WS_NTLS)  echo "8880" ;;
        DROPBEAR)     echo "109, 143, 1443" ;;
        BADVPN)       echo "7100, 7200, 7300" ;;
        VMESS_TLS)    echo "443" ;;
        VLESS_TLS)    echo "443" ;;
        TROJAN_TLS)   echo "443" ;;
        SLOWDNS)      echo "5300" ;;
        OHP)          echo "8181" ;;
        *)            echo "-" ;;
    esac
}

sys_port() { __si_ports_default "$1"; }

# ------------------------------------------------------------
#  Account counters (best-effort, used by submenus)
# ------------------------------------------------------------
sys_count_ssh() {
    # Convention: /etc/ssh/.ssh.db with rows "### user expiry"
    if [[ -r /etc/ssh/.ssh.db ]]; then
        grep -c '^###' /etc/ssh/.ssh.db 2>/dev/null || echo 0
        return
    fi
    echo 0
}

sys_count_xray() {
    local file="$1"
    if [[ -r "$file" ]]; then
        grep -c '^#' "$file" 2>/dev/null || echo 0
        return
    fi
    echo 0
}

sys_count_vmess()  { sys_count_xray /etc/xray/.vmess.db ; }
sys_count_vless()  { sys_count_xray /etc/xray/.vless.db ; }
sys_count_trojan() { sys_count_xray /etc/xray/.trojan.db ; }
