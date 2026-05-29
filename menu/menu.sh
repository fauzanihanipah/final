#!/usr/bin/env bash
# ============================================================
#  DEWA TUNNELING PANEL — Main Dashboard
#  ----------------------------------------------------------
#  Renders the full dashboard:
#    1. Gradient header banner
#    2. VPS Information card
#    3. System Resource card (with inline progress bars)
#    4. Service Status card
#    5. Port Information card
#    6. Main Menu card
#    7. Footer banner
#
#  UI logic only — calls into lib/ui.sh + lib/sysinfo.sh.
#  Submenu actions dispatch to scripts in the same directory.
# ============================================================

set -u

# Resolve the directory of this script so it works regardless of cwd.
__DEWA_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=lib/ui.sh
source "${__DEWA_DIR}/lib/ui.sh"
# shellcheck source=lib/sysinfo.sh
source "${__DEWA_DIR}/lib/sysinfo.sh"

# Render an inline horizontal usage bar — used inside the
# Resource card. Returns a styled string, ANSI-safe.
__usage_bar() {
    local percent="$1" width="${2:-20}"
    local filled=$(( percent * width / 100 ))
    (( filled > width )) && filled=$width
    local empty=$(( width - filled ))
    local color="$C_GREEN"
    (( percent >= 60 )) && color="$C_YELLOW"
    (( percent >= 85 )) && color="$C_RED"
    local fill empty_block
    fill=$(printf '%*s' "$filled" '' | tr ' ' '█')
    empty_block=$(printf '%*s' "$empty" '' | tr ' ' '░')
    printf '%s%s%s%s%s' "${color}" "${fill}" "${C_GRAY}" "${empty_block}" "${RESET}"
}

# Build a "Label : [bar] N%" row body for the resource card.
# Uses the same label column width as ui_card_kv (10) so colons align
# perfectly with the rows underneath that use ui_card_kv directly.
__resource_row() {
    local label="$1" percent="$2"
    local label_w=10
    local llen=${#label}
    local pad=$(( label_w - llen ))
    (( pad < 0 )) && pad=0
    printf '%s%s%s %s:%s %s  %s%3d%%%s' \
        "${C_LABEL}" "$label" "$(printf '%*s' "$pad" '')" \
        "${C_GRAY}" "${RESET}" \
        "$(__usage_bar "$percent" 22)" \
        "${BOLD}${C_VALUE}" "$percent" "${RESET}"
}

draw_header() {
    ui_clear
    ui_header "DEWA TUNNELING PANEL v5" "ENTERPRISE EDITION PREMIUM"
    ui_blank
}

draw_card_vps_info() {
    ui_card_top "VPS INFORMATION"
    ui_card_kv "Hostname" "$(sys_hostname)"
    ui_card_kv "Domain"   "$(sys_domain)"
    ui_card_kv "OS"       "$(sys_os)"
    ui_card_kv "Kernel"   "$(sys_kernel)"
    ui_card_kv "Uptime"   "$(sys_uptime)"
    ui_card_kv "IP"       "$(sys_ip)"
    ui_card_kv "Timezone" "$(sys_timezone)"
    ui_card_kv "Date"     "$(sys_date)"
    ui_card_bottom
    ui_blank
}

draw_card_resources() {
    local cpu ram disk net
    cpu=$(sys_cpu_usage)
    ram=$(sys_ram_usage)
    disk=$(sys_disk_usage /)
    net=$(sys_network_status)

    ui_card_top "SYSTEM RESOURCE"
    ui_card_row "$(__resource_row "CPU Usage"  "$cpu")"
    ui_card_row "$(__resource_row "RAM Usage"  "$ram")"
    ui_card_row "$(__resource_row "Disk Usage" "$disk")"

    # Network status row (text + dot) — built so the colon column
    # lines up with all ui_card_kv rows above (label width = 10).
    local net_color net_state
    case "$net" in
        NORMAL)  net_color="$C_GREEN"  ; net_state="NORMAL"  ;;
        SLOW)    net_color="$C_YELLOW" ; net_state="SLOW"    ;;
        OFFLINE) net_color="$C_RED"    ; net_state="OFFLINE" ;;
        *)       net_color="$C_GRAY"   ; net_state="$net"    ;;
    esac
    local nlabel="Network"
    local npad=$(( 10 - ${#nlabel} ))
    ui_card_row "${C_LABEL}${nlabel}$(printf '%*s' "$npad" '')${RESET} ${C_GRAY}:${RESET} ${net_color}${DOT}${RESET} ${BOLD}${net_color}${net_state}${RESET}"
    ui_card_kv "Load Avg" "$(sys_load_avg)"
    ui_card_kv "Memory"   "$(sys_ram_human)"
    ui_card_kv "Disk"     "$(sys_disk_human)"
    ui_card_bottom
    ui_blank
}

draw_card_services() {
    ui_card_top "SERVICE STATUS"
    local label unit state
    for label in "${SYS_SERVICES[@]}"; do
        unit=$(sys_service_unit "$label")
        state=$(sys_service_status "$unit")
        ui_card_status "$label" "$state"
    done
    ui_card_bottom
    ui_blank
}

draw_card_ports() {
    ui_card_top "PORT INFORMATION"
    ui_card_kv "SSH TCP"      "$(sys_port SSH_TCP)"      14
    ui_card_kv "SSH SSL"      "$(sys_port SSH_SSL)"      14
    ui_card_kv "SSH WS TLS"   "$(sys_port SSH_WS_TLS)"   14
    ui_card_kv "SSH WS NTLS"  "$(sys_port SSH_WS_NTLS)"  14
    ui_card_kv "DROPBEAR"     "$(sys_port DROPBEAR)"     14
    ui_card_kv "BADVPN"       "$(sys_port BADVPN)"       14
    ui_card_kv "VMESS TLS"    "$(sys_port VMESS_TLS)"    14
    ui_card_kv "VLESS TLS"    "$(sys_port VLESS_TLS)"    14
    ui_card_kv "TROJAN TLS"   "$(sys_port TROJAN_TLS)"   14
    ui_card_kv "SLOWDNS"      "$(sys_port SLOWDNS)"      14
    ui_card_bottom
    ui_blank
}

draw_card_main_menu() {
    ui_card_top "MAIN MENU"
    ui_card_menu "01" "SSH MANAGEMENT"
    ui_card_menu "02" "VMESS MANAGEMENT"
    ui_card_menu "03" "VLESS MANAGEMENT"
    ui_card_menu "04" "TROJAN MANAGEMENT"
    ui_card_menu "05" "BACKUP & RESTORE"
    ui_card_menu "06" "MONITORING"
    ui_card_menu "07" "SYSTEM SETTINGS"
    ui_card_menu "08" "ADMIN MANAGEMENT"
    ui_card_menu "09" "UPDATE PANEL"
    ui_card_menu "00" "EXIT"
    ui_card_bottom
    ui_blank
}

draw_dashboard() {
    draw_header
    draw_card_vps_info
    draw_card_resources
    draw_card_services
    draw_card_ports
    draw_card_main_menu
    ui_footer
}

# Dispatch a numeric main-menu choice to the right submenu script.
dispatch() {
    local choice="$1"
    local target=""
    case "$choice" in
        1|01) target="ssh.sh"     ;;
        2|02) target="vmess.sh"   ;;
        3|03) target="vless.sh"   ;;
        4|04) target="trojan.sh"  ;;
        5|05) target="backup.sh"  ;;
        6|06) target="monitor.sh" ;;
        7|07) target="system.sh"  ;;
        8|08) target="admin.sh"   ;;
        9|09) target="update.sh"  ;;
        0|00|q|Q|exit)
            ui_blank
            ui_notify_box info "Goodbye — DEWA TUNNELING PANEL closed cleanly."
            exit 0
            ;;
        "")
            return
            ;;
        *)
            ui_notify_warning "Unknown option: '$choice' — please select a number from the menu."
            ui_pause
            return
            ;;
    esac
    if [[ -x "${__DEWA_DIR}/${target}" ]]; then
        bash "${__DEWA_DIR}/${target}"
    elif [[ -f "${__DEWA_DIR}/${target}" ]]; then
        bash "${__DEWA_DIR}/${target}"
    else
        ui_notify_error "Submenu script not found: ${target}"
        ui_pause
    fi
}

main_loop() {
    local choice
    while true; do
        draw_dashboard
        ui_prompt "Select menu"
        read -r choice || exit 0
        dispatch "$choice"
    done
}

# Allow this file to be sourced (for testing) without auto-running.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main_loop
fi
