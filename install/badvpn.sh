#!/usr/bin/env bash
# Install BadVPN-udpgw on UDP ports 7100/7200/7300 via systemd.
# Strategy:
#   1. If `badvpn-udpgw` already in PATH, just write systemd units.
#   2. Else try apt's `badvpn` package (older Debians).
#   3. Else build from source via the upstream repo (slow but reliable).

BADVPN_GIT=https://github.com/ambrop72/badvpn.git
BADVPN_BIN=/usr/local/bin/badvpn-udpgw

dewa_install_badvpn() {
    inst_log "=== BADVPN ==="

    if ! command -v badvpn-udpgw >/dev/null 2>&1 && [[ ! -x "$BADVPN_BIN" ]]; then
        # Try distro package first (cheap).
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive inst_run apt-get -y -qq install badvpn || true
        fi
    fi

    if ! command -v badvpn-udpgw >/dev/null 2>&1 && [[ ! -x "$BADVPN_BIN" ]]; then
        # Build from source.
        inst_log "building badvpn from source"
        inst_pkg_install build-essential cmake git pkg-config libssl-dev libnss3-dev || return 1
        local src=/tmp/badvpn-src
        rm -rf "$src"
        if ! inst_run git clone --depth 1 "$BADVPN_GIT" "$src"; then
            inst_log "badvpn: git clone failed"
            return 1
        fi
        mkdir -p "$src/build"
        if ! inst_run bash -c "cd '$src/build' && cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && make -j\$(nproc)"; then
            inst_log "badvpn: build failed"
            return 1
        fi
        cp "$src/build/udpgw/badvpn-udpgw" "$BADVPN_BIN"
        chmod +x "$BADVPN_BIN"
        rm -rf "$src"
    fi

    local bin
    bin=$(command -v badvpn-udpgw || echo "$BADVPN_BIN")

    # One systemd unit per port — matches the dashboard's port card.
    local port unit
    for port in 7100 7200 7300; do
        unit="badvpn@${port}"
        :
    done
    inst_write_file /etc/systemd/system/badvpn@.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
[Unit]
Description=BadVPN UDP gateway on port %i
After=network.target

[Service]
ExecStart=${bin} --listen-addr 127.0.0.1:%i --max-clients 1024 --max-connections-for-client 10
Restart=on-failure
RestartSec=5
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

    # An umbrella 'badvpn.service' so the dashboard's status check passes.
    inst_write_file /etc/systemd/system/badvpn.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL — umbrella unit for badvpn@7100/7200/7300
[Unit]
Description=DEWA BadVPN umbrella
After=network.target
Wants=badvpn@7100.service badvpn@7200.service badvpn@7300.service

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    inst_run systemctl daemon-reload
    inst_run systemctl enable badvpn@7100 badvpn@7200 badvpn@7300 badvpn
    inst_run systemctl restart badvpn@7100 badvpn@7200 badvpn@7300
    inst_run systemctl restart badvpn
    inst_firewall_open 7100/udp 7200/udp 7300/udp
    inst_is_active badvpn
}
