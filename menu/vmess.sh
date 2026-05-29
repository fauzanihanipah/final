#!/usr/bin/env bash
# DEWA TUNNELING PANEL — VMESS Management submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="VMESS MANAGEMENT"
SUBMENU_SUBTITLE="Xray-core · TLS · WebSocket · gRPC"

submenu_info_card() {
    ui_card_top "VMESS OVERVIEW"
    ui_card_kv "Total Account" "$(sys_count_vmess)" 14
    ui_card_kv "TLS Port"      "$(sys_port VMESS_TLS)" 14
    ui_card_kv "Domain"        "$(sys_domain)" 14
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Create VMESS Account|add-vm"
    "02|Create Trial VMESS|trial-vm"
    "03|Renew VMESS Account|renew-vm"
    "04|Delete VMESS Account|del-vm"
    "05|User Detail|cek-vm"
    "06|Online User|usr-vm"
    "07|Reset Bandwidth|reset-vm"
    "00|Back|__back"
)

submenu_run
