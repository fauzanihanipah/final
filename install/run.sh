#!/usr/bin/env bash
# ============================================================
#  Service installation orchestrator.
#  ----------------------------------------------------------
#  Sourced by install.sh after the panel files have been
#  copied to $INSTALL_DIR. Each service module owns its own
#  install logic and returns 0 on success.
#
#  Failures of individual services are reported via the UI
#  but never abort the whole installation.
# ============================================================

[[ -n "${__DEWA_RUN_LOADED:-}" ]] && return 0
__DEWA_RUN_LOADED=1

__RUN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=common.sh
source "${__RUN_DIR}/common.sh"
for f in bbr ipv6 ssh dropbear stunnel nginx xray badvpn slowdns fail2ban; do
    # shellcheck disable=SC1090
    source "${__RUN_DIR}/${f}.sh"
done

# Service registry: "Display Name|systemd unit|installer function"
DEWA_SERVICES=(
    "BBR              |${__SENTINEL_NONE:-}|dewa_install_bbr"
    "DISABLE IPv6     |${__SENTINEL_NONE:-}|dewa_install_ipv6_disable"
    "SSH              |$(inst_ssh_unit)|dewa_install_ssh"
    "DROPBEAR         |dropbear|dewa_install_dropbear"
    "STUNNEL          |$(inst_stunnel_unit)|dewa_install_stunnel"
    "XRAY             |xray|dewa_install_xray"
    "NGINX            |nginx|dewa_install_nginx"
    "BADVPN           |badvpn|dewa_install_badvpn"
    "FAIL2BAN         |fail2ban|dewa_install_fail2ban"
    "SLOWDNS          |slowdns|dewa_install_slowdns"
)

# Run all services and report progress via the UI library.
# Requires ui.sh to be sourced by the caller (install.sh does that).
dewa_run_all_services() {
    local total=${#DEWA_SERVICES[@]} idx=0
    local ok=0 warn=0 fail=0
    local entry name unit fn rc base percent
    local -a results=()

    inst_pkg_update

    ui_card_top "INSTALLING SERVICES"
    for entry in "${DEWA_SERVICES[@]}"; do
        idx=$(( idx + 1 ))
        name="${entry%%|*}"
        local rest="${entry#*|}"
        unit="${rest%%|*}"
        fn="${rest##*|}"

        # Trim trailing whitespace from name.
        name="${name%"${name##*[![:space:]]}"}"

        # Show the service line as "running" before invoking.
        ui_card_row "$(printf '%b▶%b %-12s %b…installing%b' "$C_PRIMARY" "$RESET" "$name" "$C_GRAY" "$RESET")"

        if "$fn"; then rc=0; else rc=$?; fi

        # Resolve final status: prefer systemd state when a unit was given.
        local state state_color icon
        if [[ -n "$unit" ]] && command -v systemctl >/dev/null 2>&1; then
            if systemctl is-active --quiet "$unit"; then
                state=ACTIVE
            else
                state=OFFLINE
            fi
        else
            (( rc == 0 )) && state=ACTIVE || state=OFFLINE
        fi

        case "$state" in
            ACTIVE)  state_color="$C_GREEN";  icon="✔" ; ok=$(( ok+1 ))   ;;
            OFFLINE) state_color="$C_RED";    icon="✘" ; fail=$(( fail+1 )) ;;
            *)       state_color="$C_YELLOW"; icon="⚠" ; warn=$(( warn+1 )) ;;
        esac
        results+=("${state_color}${icon}${RESET} ${name} ${state_color}${state}${RESET}")

        # Update progress in the resource section below.
        percent=$(( idx * 100 / total ))
        printf '\033[s'        # save cursor
    done
    ui_card_bottom

    # Final summary card.
    ui_blank
    ui_card_top "SERVICE INSTALL RESULT"
    local r
    for r in "${results[@]}"; do
        ui_card_row "$r"
    done
    ui_card_separator
    ui_card_row "$(printf '%b✔ %d active%b   %b⚠ %d warning%b   %b✘ %d failed%b' \
        "$C_GREEN" "$ok" "$RESET" \
        "$C_YELLOW" "$warn" "$RESET" \
        "$C_RED" "$fail" "$RESET")"
    ui_card_bottom

    inst_log "summary: ok=$ok warn=$warn fail=$fail"

    return 0
}
