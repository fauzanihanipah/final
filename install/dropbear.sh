#!/usr/bin/env bash
# Install Dropbear and listen on 109, 143, 80 — standard alt-SSH ports.

dewa_install_dropbear() {
    inst_log "=== DROPBEAR ==="

    inst_pkg_install dropbear || return 1

    inst_backup_once /etc/default/dropbear
    inst_write_file /etc/default/dropbear 0644 <<'EOF'
# Managed by DEWA TUNNELING PANEL
# Note: ports 80 and 443 are intentionally NOT used here — those belong
# to nginx (ACME on 80, TLS termination on 443).  Dropbear keeps a small
# spread on 109/143 plus a high port for redundancy.
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -p 1443"
DROPBEAR_BANNER=""
DROPBEAR_RECEIVE_WINDOW=65536
EOF

    # Make sure /bin/false is allowed as a shell so dropbear users can be
    # authenticated even when their shell is /bin/false (used for tunneling).
    if ! grep -q '/bin/false' /etc/shells 2>/dev/null; then
        echo /bin/false >> /etc/shells
    fi
    if ! grep -q '/usr/sbin/nologin' /etc/shells 2>/dev/null; then
        echo /usr/sbin/nologin >> /etc/shells
    fi

    inst_systemd_enable dropbear
    inst_firewall_open 109 143 1443
    inst_is_active dropbear
}
