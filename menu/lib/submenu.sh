#!/usr/bin/env bash
# ============================================================
#  Shared submenu runner — used by every submenu script so the
#  rendering logic is defined exactly once.
#
#  A submenu script declares:
#     SUBMENU_TITLE="SSH MANAGEMENT"
#     SUBMENU_ITEMS=(
#       "01|Create SSH Account|add-ssh"
#       "00|Back|__back"
#     )
#  …then calls   submenu_run
# ============================================================

[[ -n "${__DEWA_SUBMENU_LOADED:-}" ]] && return 0
__DEWA_SUBMENU_LOADED=1

# Path to the menu directory (parent of lib/).
__SUB_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# shellcheck source=ui.sh
source "${__SUB_DIR}/lib/ui.sh"
# shellcheck source=sysinfo.sh
source "${__SUB_DIR}/lib/sysinfo.sh"

# ------------------------------------------------------------
#  Action helpers — invoked by submenu items via the 3rd field.
# ------------------------------------------------------------

# Sentinel: tells submenu_run to break out of its loop.
__back() { return 99; }

# Run an external command if available, otherwise show a friendly
# placeholder so the UI stays consistent on a fresh install.
sub_run() {
    local cmd="$1"; shift || true
    local label="${SUB_LAST_LABEL:-$cmd}"
    if [[ -z "$cmd" || "$cmd" == "__back" ]]; then return; fi
    if command -v "$cmd" >/dev/null 2>&1; then
        ui_blank
        ui_notify_info "Launching: ${cmd} ${*}"
        ui_blank
        "$cmd" "$@"
        local rc=$?
        ui_blank
        if (( rc == 0 )); then
            ui_notify_success "${label} completed successfully."
        else
            ui_notify_error "${label} exited with status ${rc}."
        fi
    else
        ui_blank
        ui_notify_warning "Backend command '${cmd}' is not installed yet."
        ui_notify_info    "Install the chanelog/bin package on the VPS to enable this action."
        ui_notify_info    "Repository: https://github.com/chanelog/bin"
    fi
    ui_pause
}

# ------------------------------------------------------------
#  Render + run a submenu defined by SUBMENU_TITLE / SUBMENU_ITEMS
# ------------------------------------------------------------
submenu_run() {
    local title="${SUBMENU_TITLE:-MENU}"
    local subtitle="${SUBMENU_SUBTITLE:-}"
    local -n items="SUBMENU_ITEMS"

    while true; do
        ui_clear
        ui_header "$title" "${subtitle:-DEWA TUNNELING PANEL}"
        ui_blank

        # Optional info card defined by the submenu (callable name).
        if declare -F submenu_info_card >/dev/null 2>&1; then
            submenu_info_card
            ui_blank
        fi

        ui_card_top "$title"
        local entry idx label
        for entry in "${items[@]}"; do
            idx="${entry%%|*}"
            local rest="${entry#*|}"
            label="${rest%%|*}"
            ui_card_menu "$idx" "$label"
        done
        ui_card_bottom
        ui_blank
        ui_footer
        ui_prompt "Select option"

        local choice
        read -r choice || return 0

        # Match by index field (zero-padded or stripped).
        local found=""
        for entry in "${items[@]}"; do
            idx="${entry%%|*}"
            local rest="${entry#*|}"
            label="${rest%%|*}"
            local action="${rest#*|}"
            if [[ "$choice" == "$idx" || "$choice" == "${idx#0}" ]]; then
                found=1
                SUB_LAST_LABEL="$label"
                if [[ "$action" == "__back" ]]; then
                    return 0
                fi
                # If the action is a shell function, call it directly.
                if declare -F "$action" >/dev/null 2>&1; then
                    ui_blank
                    "$action"
                    local rc=$?
                    ui_blank
                    (( rc == 99 )) && return 0
                    ui_pause
                else
                    sub_run $action
                fi
                break
            fi
        done

        if [[ -z "$found" ]]; then
            ui_notify_warning "Unknown option: '$choice'"
            ui_pause
        fi
    done
}
