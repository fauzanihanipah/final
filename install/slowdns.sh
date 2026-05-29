#!/usr/bin/env bash
# SlowDNS requires custom DNS NS records on the user's domain plus a
# pre-built binary that isn't widely packaged. We create a placeholder
# systemd unit so the dashboard can show a clear WARNING state instead
# of OFFLINE — and the actual installer is exposed via the panel's
# System Settings menu, which can be re-run after DNS is configured.

dewa_install_slowdns() {
    inst_log "=== SLOWDNS (placeholder) ==="

    # If a real slowdns binary already exists, use it as-is.
    local bin
    bin=$(command -v slowdns 2>/dev/null || command -v dnstt-server 2>/dev/null || true)

    if [[ -z "$bin" ]]; then
        inst_log "slowdns binary not found — leaving service unconfigured"
        # Don't create a systemd unit; the dashboard will continue to show
        # OFFLINE for SLOWDNS, which is honest. Users wire it up later via
        # the panel's System Settings menu.
        return 0
    fi

    inst_write_file /etc/systemd/system/slowdns.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
[Unit]
Description=SlowDNS server
After=network.target

[Service]
ExecStart=${bin} -udp :5300
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    inst_run systemctl daemon-reload
    inst_run systemctl enable slowdns
    inst_run systemctl restart slowdns
    inst_firewall_open 5300/udp
    inst_is_active slowdns
}
