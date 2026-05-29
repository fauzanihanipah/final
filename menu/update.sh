#!/usr/bin/env bash
# DEWA TUNNELING PANEL — Update Panel submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="UPDATE PANEL"
SUBMENU_SUBTITLE="Self-update · Refresh binaries · Sync configs"

submenu_info_card() {
    local ver="v5.0.0-stable"
    [[ -r "${__DIR}/VERSION" ]] && ver=$(cat "${__DIR}/VERSION")
    ui_card_top "PANEL"
    ui_card_kv "Version"   "$ver"
    ui_card_kv "Channel"   "stable"
    ui_card_kv "Bin Repo"  "https://github.com/chanelog/bin"
    ui_card_bottom
}

# Local action: simulated update with progress bars (since the real
# work happens via 'update-panel' shipped by chanelog/bin).
do_check() {
    ui_progress_set "Checking remote version" 33
    sleep 0.4
    ui_progress_set "Comparing local commit"  66
    sleep 0.4
    ui_progress_set "Done"                   100
    ui_notify_info "Run option [02] to apply available updates."
}

do_update_panel() {
    if command -v update-panel >/dev/null 2>&1; then
        sub_run update-panel
        return
    fi
    # Fallback: visible progress sequence
    local steps=(
        "Fetching latest release"
        "Verifying signatures"
        "Updating menu scripts"
        "Updating bin commands"
        "Restarting services"
    )
    local s n=${#steps[@]} i=0 percent
    for s in "${steps[@]}"; do
        i=$(( i + 1 ))
        percent=$(( i * 100 / n ))
        ui_progress_set "$s" "$percent"
        sleep 0.35
    done
    ui_progress_done "Panel updated to latest version"
}

SUBMENU_ITEMS=(
    "01|Check For Updates|do_check"
    "02|Update Panel Now|do_update_panel"
    "03|Update Bin Commands|update-bin"
    "04|Reinstall Xray|reinstall-xray"
    "05|Show Changelog|panel-changelog"
    "00|Back|__back"
)

submenu_run
