#!/usr/bin/env bash
# DEWA TUNNELING PANEL — Update Panel submenu
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${__DIR}/lib/submenu.sh"

SUBMENU_TITLE="UPDATE PANEL"
SUBMENU_SUBTITLE="Self-update · Refresh binaries · Sync configs"

submenu_info_card() {
    local ver="v5.0.0-stable"
    [[ -r "${__DIR}/VERSION" ]] && ver=$(cat "${__DIR}/VERSION")
    local last_update="unknown"
    [[ -d /opt/dewa-panel-src/.git ]] && last_update=$(git -C /opt/dewa-panel-src log -1 --format='%h · %ad' --date=short 2>/dev/null)
    ui_card_top "PANEL"
    ui_card_kv "Version"     "$ver"  14
    ui_card_kv "Channel"     "${DEWA_BRANCH:-main}" 14
    ui_card_kv "Last Update" "$last_update" 14
    ui_card_kv "Bin Repo"    "https://github.com/chanelog/bin" 14
    ui_card_bottom
}

# Show available remote version without applying it.
do_check() {
    if ! command -v git >/dev/null 2>&1; then
        ui_notify_warning "git not installed — install with 'apt install git' first."
        return
    fi
    local repo="${DEWA_REPO:-https://github.com/fauzanihanipah/final}"
    local branch="${DEWA_BRANCH:-main}"
    ui_progress_set "Checking ${repo}#${branch}" 50
    local remote
    remote=$(git ls-remote --heads "$repo" "$branch" 2>/dev/null | awk '{print substr($1,1,7)}')
    ui_progress_set "Done" 100
    if [[ -z "$remote" ]]; then
        ui_notify_warning "Could not reach ${repo}."
        return
    fi
    local local_sha="(none)"
    [[ -d /opt/dewa-panel-src/.git ]] && local_sha=$(git -C /opt/dewa-panel-src rev-parse --short HEAD 2>/dev/null)
    ui_blank
    ui_card_top "VERSION CHECK"
    ui_card_kv "Local"  "$local_sha" 10
    ui_card_kv "Remote" "$remote"    10
    ui_card_bottom
    if [[ "$local_sha" != "$remote" ]]; then
        ui_blank
        ui_notify_info "Update available — choose option [02] to apply."
    else
        ui_blank
        ui_notify_success "Panel is up-to-date."
    fi
}

# Run the real update via the update-panel CLI wrapper.
do_update_panel() {
    if command -v update-panel >/dev/null 2>&1; then
        ui_blank
        ui_notify_info "Pulling latest version + re-running installer…"
        ui_blank
        update-panel
    else
        ui_notify_warning "update-panel command not found — re-run install.sh manually."
    fi
}

# Set / replace the panel's domain (delegates to change-domain wrapper).
do_change_domain() {
    if command -v change-domain >/dev/null 2>&1; then
        ui_blank
        change-domain
    else
        ui_notify_warning "change-domain command not found — installer was not completed."
    fi
}

SUBMENU_ITEMS=(
    "01|Check For Updates|do_check"
    "02|Update Panel Now|do_update_panel"
    "03|Change Domain|do_change_domain"
    "04|Renew TLS Certificate|renew-cert"
    "05|Reinstall Xray|reinstall-xray"
    "06|Show Changelog|panel-changelog"
    "00|Back|__back"
)

submenu_run
