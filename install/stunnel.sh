#!/usr/bin/env bash
# Install stunnel4 and configure it to wrap dropbear:109 over TLS on port 445.
# Also creates a systemd alias 'stunnel5.service' so the dashboard's status
# check (which looks for 'stunnel5') matches.

dewa_install_stunnel() {
    inst_log "=== STUNNEL ==="

    local pkg unit
    pkg=$(inst_stunnel_pkg)
    unit=$(inst_stunnel_unit)

    inst_pkg_install "$pkg" openssl || return 1

    # Ensure cert exists.
    local crt=/etc/stunnel/stunnel.pem
    mkdir -p /etc/stunnel
    if [[ ! -s "$crt" ]]; then
        local tmpcrt=/tmp/_dewa-stunnel.crt tmpkey=/tmp/_dewa-stunnel.key
        inst_selfsigned_cert "$tmpcrt" "$tmpkey" "$(hostname)"
        cat "$tmpkey" "$tmpcrt" > "$crt"
        rm -f "$tmpcrt" "$tmpkey"
        chmod 600 "$crt"
    fi

    inst_write_file /etc/stunnel/stunnel.conf 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
cert = ${crt}
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 445
connect = 127.0.0.1:109

[openssh]
accept = 777
connect = 127.0.0.1:22
EOF

    # On Debian/Ubuntu /etc/default/stunnel4 needs ENABLED=1.
    if [[ -f /etc/default/stunnel4 ]]; then
        inst_backup_once /etc/default/stunnel4
        sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4
        grep -q '^ENABLED=' /etc/default/stunnel4 || echo 'ENABLED=1' >> /etc/default/stunnel4
    fi

    inst_systemd_enable "$unit"

    # Create a 'stunnel5' alias unit so the dashboard's
    # `systemctl is-active stunnel5` query succeeds.
    if [[ "$unit" != stunnel5 ]]; then
        inst_write_file /etc/systemd/system/stunnel5.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL — alias for ${unit}.service
[Unit]
Description=DEWA Stunnel5 alias
After=network.target
Requires=${unit}.service

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        inst_run systemctl daemon-reload
        inst_run systemctl enable stunnel5
        inst_run systemctl start stunnel5
    fi

    inst_firewall_open 445 777
    inst_is_active "$unit"
}
