#!/usr/bin/env bash
# Install Xray-core via the official installer and drop in a minimal
# multi-protocol config (vmess/vless/trojan over websocket on loopback).
# Xray is fronted by Nginx for TLS termination.

XRAY_OFFICIAL_INSTALLER="https://github.com/XTLS/Xray-install/raw/main/install-release.sh"

dewa_install_xray() {
    inst_log "=== XRAY ==="

    if ! command -v curl >/dev/null 2>&1; then
        inst_pkg_install curl ca-certificates || return 1
    fi

    if ! command -v xray >/dev/null 2>&1; then
        # Official installer drops xray to /usr/local/bin and creates xray.service.
        if ! inst_run bash -c "curl -fsSL ${XRAY_OFFICIAL_INSTALLER} | bash -s -- install"; then
            inst_log "xray official installer failed"
            return 1
        fi
    fi

    mkdir -p /usr/local/etc/xray /var/log/xray /etc/xray
    touch /var/log/xray/access.log /var/log/xray/error.log 2>/dev/null || true

    # Persist UUIDs/passwords for re-runs.
    local uuid_file=/etc/xray/.uuid
    local trojan_pw_file=/etc/xray/.trojan_password
    if [[ ! -s "$uuid_file" ]]; then
        if command -v xray >/dev/null 2>&1; then
            xray uuid > "$uuid_file" 2>/dev/null || cat /proc/sys/kernel/random/uuid > "$uuid_file"
        else
            cat /proc/sys/kernel/random/uuid > "$uuid_file"
        fi
    fi
    if [[ ! -s "$trojan_pw_file" ]]; then
        head -c 16 /dev/urandom | base64 | tr -d '=+/' | cut -c1-20 > "$trojan_pw_file"
    fi
    local UUID TROJAN_PW
    UUID=$(cat "$uuid_file")
    TROJAN_PW=$(cat "$trojan_pw_file")

    inst_write_file /usr/local/etc/xray/config.json 0644 <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "vmess-ws",
      "listen": "127.0.0.1",
      "port": 10001,
      "protocol": "vmess",
      "settings": { "clients": [ { "id": "${UUID}" } ] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "tag": "vless-ws",
      "listen": "127.0.0.1",
      "port": 10002,
      "protocol": "vless",
      "settings": { "clients": [ { "id": "${UUID}" } ], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    },
    {
      "tag": "trojan-ws",
      "listen": "127.0.0.1",
      "port": 10003,
      "protocol": "trojan",
      "settings": { "clients": [ { "password": "${TROJAN_PW}" } ] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ]
}
EOF

    # Seed the panel's account dbs so the menu's counters work even before
    # the user creates real accounts.
    : > /etc/xray/.vmess.db
    : > /etc/xray/.vless.db
    : > /etc/xray/.trojan.db

    inst_systemd_enable xray
    inst_is_active xray
}
