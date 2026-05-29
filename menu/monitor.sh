#!/usr/bin/env bash
# DEWA TUNNELING PANEL — Monitoring submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="MONITORING"
SUBMENU_SUBTITLE="Real-time · Logs · Bandwidth · Threats"

submenu_info_card() {
    ui_card_top "LIVE METRICS"
    ui_card_kv "CPU Usage"  "$(sys_cpu_usage)%"
    ui_card_kv "RAM Usage"  "$(sys_ram_usage)%"
    ui_card_kv "Disk Usage" "$(sys_disk_usage /)%"
    ui_card_kv "Network"    "$(sys_network_status)"
    ui_card_kv "Load Avg"   "$(sys_load_avg)"
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Realtime Resource Monitor|btop"
    "02|Bandwidth Per User|bw-user"
    "03|System Logs|journalctl-tail"
    "04|Active Connections|conn-watch"
    "05|Fail2Ban Status|f2b-status"
    "06|Service Health Check|svc-check"
    "00|Back|__back"
)

submenu_run
