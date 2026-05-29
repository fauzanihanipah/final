#!/usr/bin/env bash
# ============================================================
#  DEWA TUNNELING PANEL — Service install helpers (shared)
#  ----------------------------------------------------------
#  Pure helpers used by every install/<service>.sh module.
#  No UI calls here — modules call ui_* themselves so the
#  caller controls the presentation.
# ============================================================

[[ -n "${__DEWA_INSTALL_COMMON_LOADED:-}" ]] && return 0
__DEWA_INSTALL_COMMON_LOADED=1

INSTALL_LOG=/var/log/dewa-install.log
mkdir -p "$(dirname "$INSTALL_LOG")" 2>/dev/null || true
: > "$INSTALL_LOG" 2>/dev/null || INSTALL_LOG=/tmp/dewa-install.log

inst_log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$INSTALL_LOG" 2>&1 || true
}

# Run a command, hide its output, log it. Returns the command's exit code.
inst_run() {
    inst_log "RUN: $*"
    "$@" >> "$INSTALL_LOG" 2>&1
    local rc=$?
    inst_log "  exit=$rc"
    return $rc
}

# apt/dnf/yum/apk wrapper that picks the right package manager.
inst_pkg_install() {
    local pkgs=("$@")
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive inst_run apt-get -y -qq install "${pkgs[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        inst_run dnf install -y "${pkgs[@]}"
    elif command -v yum >/dev/null 2>&1; then
        inst_run yum install -y "${pkgs[@]}"
    elif command -v apk >/dev/null 2>&1; then
        inst_run apk add --no-cache "${pkgs[@]}"
    else
        inst_log "no supported package manager found"
        return 1
    fi
}

inst_pkg_update() {
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive inst_run apt-get -qq update
    fi
}

# Enable + (re)start a systemd unit. Idempotent.
inst_systemd_enable() {
    local unit="$1"
    inst_run systemctl daemon-reload
    inst_run systemctl enable "$unit"
    inst_run systemctl restart "$unit"
}

# Write content from stdin to a file, creating parent dirs.
inst_write_file() {
    local path="$1" mode="${2:-0644}"
    mkdir -p "$(dirname "$path")"
    cat > "$path"
    chmod "$mode" "$path"
}

# Backup a file once (skip if .dewa-orig already exists).
inst_backup_once() {
    local f="$1"
    [[ -f "$f" && ! -f "$f.dewa-orig" ]] && cp -a "$f" "$f.dewa-orig"
}

# Detect ssh service name (ssh on debian/ubuntu, sshd on rhel-family).
inst_ssh_unit() {
    if systemctl list-unit-files 2>/dev/null | grep -q '^ssh\.service'; then
        echo ssh
    elif systemctl list-unit-files 2>/dev/null | grep -q '^sshd\.service'; then
        echo sshd
    else
        echo ssh
    fi
}

# Detect stunnel package + service name (stunnel4 on Ubuntu/Debian).
inst_stunnel_pkg()  { echo stunnel4; }
inst_stunnel_unit() { echo stunnel4; }

# Quietly check if a unit is active.
inst_is_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

# Open firewall ports (best-effort, no error if ufw/firewalld absent).
inst_firewall_open() {
    local port
    for port in "$@"; do
        if command -v ufw >/dev/null 2>&1; then
            inst_run ufw allow "$port" || true
        fi
        if command -v firewall-cmd >/dev/null 2>&1; then
            inst_run firewall-cmd --permanent --add-port="${port}" || true
        fi
    done
    if command -v firewall-cmd >/dev/null 2>&1; then
        inst_run firewall-cmd --reload || true
    fi
}

# Detect IP for self-signed cert SAN.
inst_self_ip() {
    local ip
    ip=$(curl -fsS --max-time 3 ifconfig.me 2>/dev/null) || true
    [[ -z "$ip" ]] && ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    [[ -z "$ip" ]] && ip="127.0.0.1"
    printf '%s' "$ip"
}

# Generate a self-signed cert (used as fallback when no domain/cert).
inst_selfsigned_cert() {
    local crt="$1" key="$2" cn="${3:-localhost}"
    if [[ -s "$crt" && -s "$key" ]]; then
        inst_log "selfsigned: keeping existing cert at $crt"
        return 0
    fi
    mkdir -p "$(dirname "$crt")" "$(dirname "$key")"
    inst_run openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout "$key" -out "$crt" -days 825 \
        -subj "/CN=${cn}" \
        -addext "subjectAltName=DNS:${cn},IP:$(inst_self_ip)"
    chmod 600 "$key" 2>/dev/null || true
    chmod 644 "$crt" 2>/dev/null || true
}
