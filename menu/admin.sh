#!/usr/bin/env bash
# DEWA TUNNELING PANEL — Admin Management submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="ADMIN MANAGEMENT"
SUBMENU_SUBTITLE="Operators · Telegram · Notifications"

submenu_info_card() {
    local who_now
    who_now=$(who am i 2>/dev/null | awk '{print $1}')
    [[ -z "$who_now" ]] && who_now=$(whoami 2>/dev/null)
    ui_card_top "ADMIN"
    ui_card_kv "Current User" "${who_now:-unknown}" 13
    ui_card_kv "Hostname"     "$(sys_hostname)" 13
    ui_card_kv "Date"         "$(sys_date)" 13
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Add Admin|add-admin"
    "02|Delete Admin|del-admin"
    "03|List Admins|list-admin"
    "04|Change Admin Password|passwd-admin"
    "05|Configure Telegram Bot|set-tele"
    "06|Test Telegram Notify|test-tele"
    "07|Auto Notify On Login|set-notify"
    "00|Back|__back"
)

submenu_run
