#!/usr/bin/env bash
# Install a WebSocket-to-SSH bridge using websocat (single static binary).
# Listens on 127.0.0.1:8880 and forwards to dropbear:109. Nginx exposes
# the same on TLS via /sshws (port 443) — see install/nginx.sh.

WSPROXY_BIN=/usr/local/bin/websocat
WSPROXY_VERSION="${DEWA_WEBSOCAT_VERSION:-v1.13.0}"
WSPROXY_URL="https://github.com/vi/websocat/releases/download/${WSPROXY_VERSION}/websocat.x86_64-unknown-linux-musl"

dewa_install_wsproxy() {
    inst_log "=== WS-SSH BRIDGE (websocat) ==="

    # Download static binary if not already present.
    if [[ ! -x "$WSPROXY_BIN" ]]; then
        if ! command -v curl >/dev/null 2>&1; then
            inst_pkg_install curl ca-certificates || return 1
        fi
        inst_log "fetching ${WSPROXY_URL}"
        if ! inst_run curl -fL --max-time 60 -o "$WSPROXY_BIN" "$WSPROXY_URL"; then
            inst_log "websocat download failed"
            return 1
        fi
        chmod +x "$WSPROXY_BIN"
    fi

    # Verify it runs.
    if ! "$WSPROXY_BIN" --version >/dev/null 2>&1; then
        inst_log "websocat refuses to run — wrong arch?"
        return 1
    fi

    # Systemd unit: TLS-side served by nginx /sshws on :443.
    # NTLS-side served directly here on 0.0.0.0:8880 so SSH-over-WS
    # without TLS works too (matches the dashboard's "SSH WS NTLS : 8880").
    inst_write_file /etc/systemd/system/ws-ssh.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL — SSH-over-WebSocket bridge
[Unit]
Description=DEWA SSH-over-WebSocket bridge (websocat)
After=network-online.target dropbear.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=${WSPROXY_BIN} --binary -E ws-l:0.0.0.0:8880 tcp:127.0.0.1:109
Restart=on-failure
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

    inst_run systemctl daemon-reload
    inst_run systemctl enable  ws-ssh
    inst_run systemctl restart ws-ssh
    inst_firewall_open 8880

    inst_is_active ws-ssh
}
