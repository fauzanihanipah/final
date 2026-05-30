#!/usr/bin/env bash
# ============================================================
#  Quick health-check tool — prints the live state of every
#  service the panel manages, plus the last few log lines for
#  any service that is not active. Designed to be the first
#  thing a user runs when "X is offline".
#
#  Invoked as the `dewa-doctor` CLI wrapper.
# ============================================================

set -u
__DOC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source UI library if available so the report uses panel styling.
if [[ -f /opt/dewa-panel/menu/lib/ui.sh ]]; then
    # shellcheck disable=SC1091
    source /opt/dewa-panel/menu/lib/ui.sh
elif [[ -f "${__DOC_DIR}/../menu/lib/ui.sh" ]]; then
    # shellcheck disable=SC1091
    source "${__DOC_DIR}/../menu/lib/ui.sh"
fi
if [[ -f /opt/dewa-panel/menu/lib/sysinfo.sh ]]; then
    # shellcheck disable=SC1091
    source /opt/dewa-panel/menu/lib/sysinfo.sh
elif [[ -f "${__DOC_DIR}/../menu/lib/sysinfo.sh" ]]; then
    # shellcheck disable=SC1091
    source "${__DOC_DIR}/../menu/lib/sysinfo.sh"
fi

# Fallback minimal helpers if UI library is missing.
if ! declare -F ui_card_top >/dev/null 2>&1; then
    ui_card_top()    { printf '\n=== %s ===\n' "$*"; }
    ui_card_row()    { printf '  %s\n' "$*"; }
    ui_card_kv()     { printf '  %-20s %s\n' "$1" "$2"; }
    ui_card_status() { printf '  %-12s %s\n' "$1" "$2"; }
    ui_card_bottom() { :; }
    ui_card_separator() { printf '  ----\n'; }
    ui_blank()       { printf '\n'; }
    ui_header()      { printf '\n*** %s — %s ***\n\n' "$1" "$2"; }
    ui_footer()      { :; }
    ui_clear()       { :; }
    ui_notify_success() { printf 'OK: %s\n' "$*"; }
    ui_notify_info()    { printf 'INFO: %s\n' "$*"; }
fi

ui_clear
ui_header "DEWA DOCTOR" "Service health diagnostic"
ui_blank

# --- Port inventory -----------------------------------------
# Show DEWA's reserved ports first and prominently, then the rest.
DEWA_RESERVED_PORTS_DISPLAY=(80 443 445 777 8880 22 109 143 444 1443)

ui_card_top "RESERVED PORT OCCUPANTS"
if command -v ss >/dev/null 2>&1; then
    for port in "${DEWA_RESERVED_PORTS_DISPLAY[@]}"; do
        line=$(ss -tlnp 2>/dev/null | awk -v p=":${port}\$" '$4 ~ p' | head -1)
        if [[ -z "$line" ]]; then
            ui_card_row "$(printf '%-7s %s' "$port" "(not bound)")"
        else
            owner=$(printf '%s' "$line" | grep -oE 'users:\(\("[^"]+"' | head -1 | sed 's/users:((//;s/"//g')
            pid=$(printf '%s' "$line" | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2)
            laddr=$(printf '%s' "$line" | awk '{print $4}')
            ui_card_row "$(printf '%-7s %-22s %s (pid %s)' "$port" "$laddr" "${owner:-?}" "${pid:-?}")"
        fi
    done
else
    ui_card_row "ss(8) not available — install iproute2"
fi
ui_card_bottom
ui_blank

ui_card_top "ALL LISTENING SOCKETS"
if command -v ss >/dev/null 2>&1; then
    while IFS= read -r line; do
        ui_card_row "$line"
    done < <(ss -tlnp 2>/dev/null \
        | awk 'NR>1 {gsub("users:","",$0); printf "%-22s %s\n", $4, $NF}' \
        | sort -u | head -30)
else
    ui_card_row "ss(8) not available — install iproute2"
fi
ui_card_bottom
ui_blank

# --- Service state ------------------------------------------
LABELS=(SSH DROPBEAR STUNNEL5 XRAY NGINX BADVPN SLOWDNS FAIL2BAN)
ui_card_top "SERVICE STATE"
declare -A FAILED=()
for label in "${LABELS[@]}"; do
    if declare -F sys_service_unit >/dev/null 2>&1; then
        unit=$(sys_service_unit "$label" 2>/dev/null)
    else
        unit="${label,,}"
    fi
    [[ -z "$unit" ]] && unit="${label,,}"

    # If the unit file doesn't exist at all, label it NOT INSTALLED
    # rather than OFFLINE so users don't think it's broken.
    if command -v systemctl >/dev/null 2>&1 \
       && ! systemctl list-unit-files 2>/dev/null | awk '{print $1}' | grep -qx "${unit}.service"; then
        ui_card_status "$label" "WARNING"   # yellow dot for "not installed"
        continue
    fi

    if declare -F sys_service_status >/dev/null 2>&1; then
        state=$(sys_service_status "$unit" 2>/dev/null || echo OFFLINE)
    else
        state=$(systemctl is-active "$unit" 2>/dev/null || echo OFFLINE)
        [[ "$state" == active ]] && state=ACTIVE || state=OFFLINE
    fi
    ui_card_status "$label" "$state"
    [[ "$state" != ACTIVE ]] && FAILED["$label"]="$unit"
done
ui_card_bottom
ui_blank

if (( ${#FAILED[@]} == 0 )); then
    ui_notify_success "All managed services are ACTIVE."
    ui_blank
    exit 0
fi

# --- Per-failed-service journal tail ------------------------
for label in "${!FAILED[@]}"; do
    unit="${FAILED[$label]}"
    ui_card_top "DIAGNOSTIC — ${label} (${unit})"
    if command -v systemctl >/dev/null 2>&1; then
        ui_card_row "is-active : $(systemctl is-active "$unit" 2>&1 | head -1)"
        ui_card_row "is-enabled: $(systemctl is-enabled "$unit" 2>&1 | head -1)"
        ui_card_separator
        ui_card_row "Last 8 journal lines:"
        if command -v journalctl >/dev/null 2>&1; then
            while IFS= read -r line; do
                ui_card_row "  $line"
            done < <(journalctl -u "$unit" -n 8 --no-pager 2>/dev/null \
                     | sed 's/[[:cntrl:]]//g' | tail -8)
        else
            ui_card_row "  (journalctl not available)"
        fi
    else
        ui_card_row "systemctl not available"
    fi
    ui_card_bottom
    ui_blank
done

ui_notify_info "Full install log: tail -100 /var/log/dewa-install.log"
ui_notify_info "Re-run installer to repair: update-panel"
ui_blank
