#!/usr/bin/env bash
# DEWA TUNNELING PANEL — Backup & Restore submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="BACKUP & RESTORE"
SUBMENU_SUBTITLE="Snapshot · Sync · Disaster Recovery"

submenu_info_card() {
    local last="never"
    [[ -r /root/backup/.last ]] && last=$(cat /root/backup/.last 2>/dev/null)
    ui_card_top "BACKUP STATUS"
    ui_card_kv "Last Backup"   "$last" 14
    ui_card_kv "Backup Folder" "/root/backup" 14
    ui_card_kv "Disk Free"     "$(sys_disk_human)" 14
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Create Full Backup|backup"
    "02|Restore From Backup|restore"
    "03|Schedule Daily Backup|backup-cron"
    "04|Send Backup To Telegram|backup-tele"
    "05|List Backups|backup-list"
    "06|Delete Old Backups|backup-clean"
    "00|Back|__back"
)

submenu_run
