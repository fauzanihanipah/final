#!/usr/bin/env bash
# DEWA TUNNELING PANEL — VLESS Management submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="VLESS MANAGEMENT"
SUBMENU_SUBTITLE="Xray-core · XTLS · Reality · gRPC"

submenu_info_card() {
    ui_card_top "VLESS OVERVIEW"
    ui_card_kv "Total Account" "$(sys_count_vless)" 14
    ui_card_kv "TLS Port"      "$(sys_port VLESS_TLS)" 14
    ui_card_kv "Domain"        "$(sys_domain)" 14
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Create VLESS Account|add-vless"
    "02|Create Trial VLESS|trial-vless"
    "03|Renew VLESS Account|renew-vless"
    "04|Delete VLESS Account|del-vless"
    "05|User Detail|cek-vless"
    "06|Online User|usr-vless"
    "07|Reset Bandwidth|reset-vless"
    "00|Back|__back"
)

submenu_run
