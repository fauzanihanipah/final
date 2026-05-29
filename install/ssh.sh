#!/usr/bin/env bash
# Configure OpenSSH: keep port 22, add a redundant port 444 for tunneling.
# Idempotent — re-running just refreshes the drop-in config.

dewa_install_ssh() {
    inst_log "=== SSH ==="

    if ! command -v sshd >/dev/null 2>&1; then
        inst_pkg_install openssh-server || return 1
    fi

    local cfg=/etc/ssh/sshd_config.d/90-dewa.conf
    inst_write_file "$cfg" 0644 <<'EOF'
# Managed by DEWA TUNNELING PANEL
Port 22
Port 444
PasswordAuthentication yes
PermitRootLogin yes
ClientAliveInterval 120
ClientAliveCountMax 2
EOF

    # On distros that ignore /etc/ssh/sshd_config.d, fall back to editing
    # the main file (idempotently).
    if ! grep -q 'sshd_config.d' /etc/ssh/sshd_config 2>/dev/null \
       && ! grep -q 'Include /etc/ssh/sshd_config.d' /etc/ssh/sshd_config 2>/dev/null; then
        inst_backup_once /etc/ssh/sshd_config
        sed -i '/^# DEWA-BEGIN/,/^# DEWA-END/d' /etc/ssh/sshd_config
        cat >> /etc/ssh/sshd_config <<'EOF'
# DEWA-BEGIN
Port 22
Port 444
PasswordAuthentication yes
PermitRootLogin yes
# DEWA-END
EOF
    fi

    local unit
    unit=$(inst_ssh_unit)
    inst_systemd_enable "$unit"
    inst_firewall_open 22 444
    inst_is_active "$unit"
}
