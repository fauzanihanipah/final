#!/usr/bin/env bash
# DEWA TUNNELING PANEL — System Settings submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="SYSTEM SETTINGS"
SUBMENU_SUBTITLE="Network · Kernel · Security"

submenu_info_card() {
    ui_card_top "SYSTEM"
    ui_card_kv "OS"       "$(sys_os)"
    ui_card_kv "Kernel"   "$(sys_kernel)"
    ui_card_kv "Arch"     "$(sys_arch)"
    ui_card_kv "Hostname" "$(sys_hostname)"
    ui_card_kv "IP"       "$(sys_ip)"
    ui_card_kv "Timezone" "$(sys_timezone)"
    ui_card_bottom
}

SUBMENU_ITEMS=(
    "01|Change Domain|change-domain"
    "02|Renew SSL Certificate|renew-cert"
    "03|Apply BBR / TCP Tuning|bbr"
    "04|Disable IPv6|disable-ipv6"
    "05|Change Timezone|change-tz"
    "06|Change Banner|change-banner"
    "07|Restart All Services|restart-all"
    "08|Speedtest|speedtest"
    "09|Reboot Server|reboot-server"
    "00|Back|__back"
)

submenu_run
