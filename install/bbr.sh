#!/usr/bin/env bash
# Apply BBR + sane TCP defaults via /etc/sysctl.d/99-dewa.conf.

dewa_install_bbr() {
    inst_log "=== BBR / TCP TUNING ==="

    inst_write_file /etc/sysctl.d/99-dewa.conf 0644 <<'EOF'
# Managed by DEWA TUNNELING PANEL
net.core.default_qdisc           = fq
net.ipv4.tcp_congestion_control  = bbr
net.ipv4.tcp_fastopen            = 3
net.ipv4.tcp_mtu_probing         = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.core.rmem_max                = 26214400
net.core.wmem_max                = 26214400
net.ipv4.tcp_rmem                = 4096 87380 26214400
net.ipv4.tcp_wmem                = 4096 65536 26214400
net.ipv4.ip_forward              = 1
EOF

    inst_run sysctl --system >/dev/null
    # Confirm BBR is active.
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
        inst_log "BBR enabled"
        return 0
    fi
    inst_log "BBR could not be enabled (kernel may not support it)"
    return 0   # non-fatal
}
