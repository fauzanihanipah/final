#!/usr/bin/env bash
# DEWA TUNNELING PANEL — SSH Management submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="SSH MANAGEMENT"
SUBMENU_SUBTITLE="OpenSSH · Dropbear · Stunnel · WebSocket"

submenu_info_card() {
    local total online
    total=$(sys_count_ssh)
    online=$(who 2>/dev/null | wc -l | tr -d ' ')
    ui_card_top "SSH OVERVIEW"
    ui_card_kv "Total Account" "$total"   14
    ui_card_kv "Online Now"    "$online"  14
    ui_card_kv "SSH Port"      "$(sys_port SSH_TCP)"      14
    ui_card_kv "SSL Port"      "$(sys_port SSH_SSL)"      14
    ui_card_kv "WS TLS Port"   "$(sys_port SSH_WS_TLS)"   14
    ui_card_kv "WS NTLS Port"  "$(sys_port SSH_WS_NTLS)"  14
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Create SSH Account|add-ssh"
    "02|Create Trial SSH|trial-ssh"
    "03|Renew SSH Account|renew-ssh"
    "04|Delete SSH Account|del-ssh"
    "05|User Detail|cek-ssh"
    "06|Online User|usr-ssh"
    "07|Multi Login Monitor|member-ssh"
    "08|Kill Multi Login|autokill"
    "09|Lock User|lock-ssh"
    "10|Unlock User|unlock-ssh"
    "00|Back|__back"
)

submenu_run
