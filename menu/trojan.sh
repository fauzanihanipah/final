#!/usr/bin/env bash
# DEWA TUNNELING PANEL — Trojan Management submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="TROJAN MANAGEMENT"
SUBMENU_SUBTITLE="Trojan-Go · TLS · WebSocket"

submenu_info_card() {
    ui_card_top "TROJAN OVERVIEW"
    ui_card_kv "Total Account" "$(sys_count_trojan)" 14
    ui_card_kv "TLS Port"      "$(sys_port TROJAN_TLS)" 14
    ui_card_kv "Domain"        "$(sys_domain)" 14
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Create Trojan Account|add-tr"
    "02|Create Trial Trojan|trial-tr"
    "03|Renew Trojan Account|renew-tr"
    "04|Delete Trojan Account|del-tr"
    "05|User Detail|cek-tr"
    "06|Online User|usr-tr"
    "07|Reset Bandwidth|reset-tr"
    "00|Back|__back"
)

submenu_run
