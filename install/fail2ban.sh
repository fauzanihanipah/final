#!/usr/bin/env bash
# Install Fail2ban with a minimal jail.local protecting SSH + Dropbear.

dewa_install_fail2ban() {
    inst_log "=== FAIL2BAN ==="

    inst_pkg_install fail2ban || return 1

    inst_write_file /etc/fail2ban/jail.local 0644 <<'EOF'
# Managed by DEWA TUNNELING PANEL
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true

[dropbear]
enabled = true
port    = 109,143,80
EOF

    inst_systemd_enable fail2ban
    inst_is_active fail2ban
}
