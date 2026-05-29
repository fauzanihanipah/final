#!/usr/bin/env bash
# Disable IPv6 system-wide. Some VPS providers' networks misbehave with
# v6, so the panel disables it by default — re-enable via the System menu.

dewa_install_ipv6_disable() {
    inst_log "=== DISABLE IPv6 ==="

    inst_write_file /etc/sysctl.d/98-dewa-ipv6.conf 0644 <<'EOF'
# Managed by DEWA TUNNELING PANEL
net.ipv6.conf.all.disable_ipv6     = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6      = 1
EOF
    inst_run sysctl --system >/dev/null
    return 0
}
