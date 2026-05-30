#!/usr/bin/env bash
# Install stunnel and run it under our OWN systemd unit (dewa-stunnel)
# instead of relying on the distro's stunnel4 wrapper, which has been
# the source of "stunnel offline" reports — its /etc/default/stunnel4
# script handling differs across Ubuntu LTS versions and silently fails
# when the conf file naming doesn't match.
#
# An alias unit 'stunnel5.service' still exists so existing tooling
# that queries stunnel5 keeps working.

dewa_install_stunnel() {
    inst_log "=== STUNNEL ==="

    # Install the binary. Package name is stunnel4 on Debian/Ubuntu,
    # stunnel on RHEL family, stunnel on Alpine.
    if command -v apt-get >/dev/null 2>&1; then
        inst_pkg_install stunnel4 openssl || return 1
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        inst_pkg_install stunnel openssl || return 1
    else
        inst_pkg_install stunnel openssl || return 1
    fi

    # Locate the binary; different distros use different names.
    local bin
    bin=$(command -v stunnel4 2>/dev/null || command -v stunnel 2>/dev/null)
    if [[ -z "$bin" ]]; then
        inst_log "stunnel binary not found after install"
        return 1
    fi

    # Disable the distro's auto-start so it can't fight with us for
    # the same listen ports.
    if [[ -f /etc/default/stunnel4 ]]; then
        inst_backup_once /etc/default/stunnel4
        sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/stunnel4
        grep -q '^ENABLED=' /etc/default/stunnel4 || echo 'ENABLED=0' >> /etc/default/stunnel4
    fi
    inst_run systemctl disable stunnel4 || true
    inst_run systemctl stop    stunnel4 || true

    # Generate a self-signed cert if one doesn't already exist.
    local crt=/etc/stunnel/dewa.pem
    mkdir -p /etc/stunnel /var/log/stunnel /var/run/stunnel
    if [[ ! -s "$crt" ]]; then
        local tmpcrt=/tmp/_dewa-stunnel.crt tmpkey=/tmp/_dewa-stunnel.key
        inst_selfsigned_cert "$tmpcrt" "$tmpkey" "$(hostname)"
        cat "$tmpkey" "$tmpcrt" > "$crt"
        rm -f "$tmpcrt" "$tmpkey"
    fi
    chmod 600 "$crt"

    # Stunnel config — runs as nobody, foregrounded under systemd.
    inst_write_file /etc/stunnel/dewa.conf 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
# Run foregrounded so systemd can supervise it directly.
foreground = yes
debug = 4
output = /var/log/stunnel/dewa.log

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

    # Our own systemd unit. 'foreground = yes' means Type=simple is correct.
    inst_write_file /etc/systemd/system/dewa-stunnel.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
[Unit]
Description=DEWA Stunnel (TLS wrapper for SSH/Dropbear)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${bin} /etc/stunnel/dewa.conf
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    inst_run systemctl daemon-reload
    inst_run systemctl enable  dewa-stunnel
    inst_run systemctl restart dewa-stunnel

    # Convenience aliases so the dashboard's status query
    # ('stunnel5' or 'stunnel') still hits us.
    local alias
    for alias in stunnel5 stunnel; do
        inst_write_file /etc/systemd/system/${alias}.service 0644 <<EOF
# Managed by DEWA TUNNELING PANEL — alias for dewa-stunnel.service
[Unit]
Description=DEWA Stunnel alias (${alias})
Requires=dewa-stunnel.service
After=dewa-stunnel.service

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        inst_run systemctl enable ${alias} || true
        inst_run systemctl start  ${alias} || true
    done
    inst_run systemctl daemon-reload

    inst_firewall_open 445 777
    inst_is_active dewa-stunnel
}
