#!/usr/bin/env bash
# ============================================================
#  DEWA TUNNELING PANEL — Core UI Library
#  ----------------------------------------------------------
#  Provides:
#    - ANSI 256 color variables
#    - Unicode box drawing primitives (rounded + double-line)
#    - Dynamic terminal width detection (80..120 cols)
#    - Gradient header renderer (blue -> cyan)
#    - Centered text & padding helpers
#    - Card builder (top / row / kv / status / separator / bottom)
#    - Notification helpers (success / warning / error / info)
#    - Animated progress bar with status messages
#
#  This library contains UI logic ONLY. No backend calls.
# ============================================================

# Idempotent guard so this can be sourced multiple times safely.
[[ -n "${__DEWA_UI_LOADED:-}" ]] && return 0
__DEWA_UI_LOADED=1

# ------------------------------------------------------------
#  ANSI helpers
# ------------------------------------------------------------
__c()  { printf '\033[38;5;%sm' "$1"; }   # 256-color fg
__bg() { printf '\033[48;5;%sm' "$1"; }   # 256-color bg

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
ITAL=$'\033[3m'

# ------------------------------------------------------------
#  Color palette
# ------------------------------------------------------------
C_PRIMARY=$(__c 39)       # cyan
C_PRIMARY_2=$(__c 45)     # cyan-2
C_BLUE=$(__c 33)          # blue
C_BLUE_DEEP=$(__c 27)     # deep blue
C_GREEN=$(__c 46)         # success
C_GREEN_SOFT=$(__c 35)
C_YELLOW=$(__c 220)       # warning
C_RED=$(__c 196)          # danger
C_MAGENTA=$(__c 207)      # info
C_GRAY=$(__c 244)         # dim
C_LABEL=$(__c 250)        # label
C_VALUE=$(__c 255)        # value
C_BORDER=$(__c 39)        # default border = primary

# Header gradient stops (blue -> cyan)
GRADIENT_STOPS=(27 33 39 45 51 87 123 159)

# ------------------------------------------------------------
#  Box drawing primitives
# ------------------------------------------------------------
# Rounded card glyphs
BOX_TL='╭' BOX_TR='╮' BOX_BL='╰' BOX_BR='╯'
BOX_H='─'  BOX_V='│'  BOX_ML='├' BOX_MR='┤'

# Double-line glyphs (header / footer banners)
HDR_TL='╔' HDR_TR='╗' HDR_BL='╚' HDR_BR='╝'
HDR_H='═'  HDR_V='║'

# Decorative full-width separator
SEP_LINE='━'

# Status dot
DOT='●'

# ------------------------------------------------------------
#  Terminal width detection
#  Card width is clamped between 64 and 96 columns to stay
#  symmetric across an 80..200 column terminal.
# ------------------------------------------------------------
ui_term_width() {
    local w
    w=$(tput cols 2>/dev/null) || w=80
    [[ -z "$w" || "$w" -lt 1 ]] && w=80
    echo "$w"
}

ui_card_width() {
    local tw min=64 max=96 cw
    tw=$(ui_term_width)
    cw=$(( tw - 4 ))
    (( cw < min )) && cw=$min
    (( cw > max )) && cw=$max
    echo "$cw"
}

# ------------------------------------------------------------
#  Internal: visible length (strips ANSI)
# ------------------------------------------------------------
__visible_len() {
    local s="$1"
    # Remove ANSI escape sequences before counting
    s=$(printf '%s' "$s" | sed -E $'s/\033\\[[0-9;]*[a-zA-Z]//g')
    # Count characters (multi-byte safe)
    echo "${#s}"
}

# Repeat a single character N times
__repeat() {
    local ch="$1" n="$2"
    local out=""
    while (( n-- > 0 )); do out+="$ch"; done
    printf '%s' "$out"
}

# ------------------------------------------------------------
#  Centered line at terminal width
# ------------------------------------------------------------
ui_center() {
    local text="$1"
    local width="${2:-$(ui_term_width)}"
    local len pad
    len=$(__visible_len "$text")
    pad=$(( (width - len) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s%b%s\n' "$pad" '' "$text" "$RESET"
}

# Centered line *inside* a card (no trailing newline reset issues)
ui_center_in() {
    local text="$1" width="$2"
    local len pad_l pad_r
    len=$(__visible_len "$text")
    pad_l=$(( (width - len) / 2 ))
    pad_r=$(( width - len - pad_l ))
    (( pad_l < 0 )) && pad_l=0
    (( pad_r < 0 )) && pad_r=0
    printf '%*s%b%*s' "$pad_l" '' "$text" "$pad_r" ''
}

# ------------------------------------------------------------
#  Gradient text (per-character color from blue to cyan)
# ------------------------------------------------------------
ui_gradient_text() {
    local text="$1"
    local len=${#text}
    local stops=${#GRADIENT_STOPS[@]}
    local i ch idx color out=""
    if (( len <= 1 )); then
        printf '%b%s%b' "$(__c "${GRADIENT_STOPS[0]}")" "$text" "$RESET"
        return
    fi
    for (( i=0; i<len; i++ )); do
        ch="${text:$i:1}"
        idx=$(( i * (stops - 1) / (len - 1) ))
        color="${GRADIENT_STOPS[$idx]}"
        out+="$(__c "$color")${BOLD}${ch}"
    done
    printf '%s%b' "$out" "$RESET"
}

# ------------------------------------------------------------
#  Decorative full-width horizontal rule
# ------------------------------------------------------------
ui_hr() {
    local color="${1:-$C_GRAY}"
    local w
    w=$(ui_term_width)
    printf '%b%s%b\n' "$color" "$(__repeat "$SEP_LINE" "$w")" "$RESET"
}

ui_blank() { printf '\n'; }

# ------------------------------------------------------------
#  HEADER & FOOTER (double-line banners with gradient title)
#  Usage: ui_header "TITLE" "SUBTITLE"
# ------------------------------------------------------------
ui_header() {
    local title="$1" subtitle="$2"
    local w cw inner
    w=$(ui_term_width)
    cw=$(ui_card_width)
    inner=$(( cw - 2 ))

    # outer pad = (terminal width - card width) / 2 -> centers the banner
    local outer_pad=$(( (w - cw) / 2 ))
    (( outer_pad < 0 )) && outer_pad=0
    local pad
    pad=$(printf '%*s' "$outer_pad" '')

    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$HDR_TL" "$(__repeat "$HDR_H" "$cw")" "$HDR_TR" "$RESET"

    # Title line (gradient)
    local title_styled
    title_styled=$(ui_gradient_text "$title")
    local title_line
    title_line=$(ui_center_in "$title_styled" "$inner")
    printf '%s%b%s%b %s %b%s%b\n' \
        "$pad" "$C_BORDER" "$HDR_V" "$RESET" "$title_line" "$C_BORDER" "$HDR_V" "$RESET"

    # Subtitle line
    if [[ -n "$subtitle" ]]; then
        local sub_styled="${C_GRAY}${ITAL}${subtitle}${RESET}"
        local sub_line
        sub_line=$(ui_center_in "$sub_styled" "$inner")
        printf '%s%b%s%b %s %b%s%b\n' \
            "$pad" "$C_BORDER" "$HDR_V" "$RESET" "$sub_line" "$C_BORDER" "$HDR_V" "$RESET"
    fi

    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$HDR_BL" "$(__repeat "$HDR_H" "$cw")" "$HDR_BR" "$RESET"
}

ui_footer() {
    local line1="${1:-DEWA TUNNELING PANEL ENTERPRISE EDITION}"
    local line2="${2:-Build : Stable Release}"
    local line3="${3:-Status: Production Ready}"
    local w cw inner
    w=$(ui_term_width)
    cw=$(ui_card_width)
    inner=$(( cw - 2 ))
    local outer_pad=$(( (w - cw) / 2 ))
    (( outer_pad < 0 )) && outer_pad=0
    local pad
    pad=$(printf '%*s' "$outer_pad" '')

    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$HDR_TL" "$(__repeat "$HDR_H" "$cw")" "$HDR_TR" "$RESET"

    local rows=("$line1" "$line2" "$line3")
    local r styled centered
    for r in "${rows[@]}"; do
        styled="${C_PRIMARY_2}${BOLD}${r}${RESET}"
        centered=$(ui_center_in "$styled" "$inner")
        printf '%s%b%s%b %s %b%s%b\n' \
            "$pad" "$C_BORDER" "$HDR_V" "$RESET" "$centered" "$C_BORDER" "$HDR_V" "$RESET"
    done

    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$HDR_BL" "$(__repeat "$HDR_H" "$cw")" "$HDR_BR" "$RESET"
}

# ------------------------------------------------------------
#  CARD primitives (rounded boxes)
# ------------------------------------------------------------
__card_outer_pad() {
    local w cw outer_pad
    w=$(ui_term_width)
    cw=$(ui_card_width)
    outer_pad=$(( (w - cw) / 2 ))
    (( outer_pad < 0 )) && outer_pad=0
    printf '%*s' "$outer_pad" ''
}

# Card top: title bar with centered or left-aligned title
ui_card_top() {
    local title="$1"
    local cw inner pad
    cw=$(ui_card_width)
    inner=$(( cw - 2 ))
    pad=$(__card_outer_pad)

    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$BOX_TL" "$(__repeat "$BOX_H" "$cw")" "$BOX_TR" "$RESET"

    if [[ -n "$title" ]]; then
        local styled="${BOLD}${C_PRIMARY_2}${title}${RESET}"
        local body
        body=$(ui_center_in "$styled" "$inner")
        printf '%s%b%s%b %s %b%s%b\n' \
            "$pad" "$C_BORDER" "$BOX_V" "$RESET" "$body" "$C_BORDER" "$BOX_V" "$RESET"
        ui_card_separator
    fi
}

# Mid-card horizontal separator
ui_card_separator() {
    local cw pad
    cw=$(ui_card_width)
    pad=$(__card_outer_pad)
    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$BOX_ML" "$(__repeat "$BOX_H" "$cw")" "$BOX_MR" "$RESET"
}

# Card bottom
ui_card_bottom() {
    local cw pad
    cw=$(ui_card_width)
    pad=$(__card_outer_pad)
    printf '%s%b%s%s%s%b\n' \
        "$pad" "$C_BORDER" "$BOX_BL" "$(__repeat "$BOX_H" "$cw")" "$BOX_BR" "$RESET"
}

# Generic content row: ui_card_row "<pre-formatted body>"
# The body is left-aligned with 1-column gutters and right-padded.
ui_card_row() {
    local body="$1"
    local cw inner pad len pad_r
    cw=$(ui_card_width)
    inner=$(( cw - 2 ))
    pad=$(__card_outer_pad)
    len=$(__visible_len "$body")
    pad_r=$(( inner - len ))
    (( pad_r < 0 )) && pad_r=0
    printf '%s%b%s%b %s%*s %b%s%b\n' \
        "$pad" "$C_BORDER" "$BOX_V" "$RESET" "$body" "$pad_r" '' \
        "$C_BORDER" "$BOX_V" "$RESET"
}

# Empty padding row (useful for breathing room)
ui_card_blank() { ui_card_row ""; }

# Key/Value row: ui_card_kv "Hostname" "server01"
ui_card_kv() {
    local label="$1" value="$2"
    local label_w=10                 # default label column width
    [[ -n "${3:-}" ]] && label_w="$3"
    local left mid right body
    left="${C_LABEL}${label}"
    # right-pad label to label_w
    local llen=${#label}
    local pad_label=$(( label_w - llen ))
    (( pad_label < 0 )) && pad_label=0
    left="${left}$(printf '%*s' "$pad_label" '')${RESET}"
    mid="${C_GRAY}:${RESET}"
    right="${C_VALUE}${value}${RESET}"
    body="${left} ${mid} ${right}"
    ui_card_row "$body"
}

# Status row: ui_card_status "SSH" "ACTIVE"   → green dot
#             ui_card_status "XRAY" "WARNING" → yellow dot
#             ui_card_status "NGINX" "OFFLINE"→ red dot
ui_card_status() {
    local name="$1" state="$2"
    local label_w=11
    [[ -n "${3:-}" ]] && label_w="$3"
    local color
    case "${state^^}" in
        ACTIVE|RUNNING|ON|OK)   color="$C_GREEN"  ; state="ACTIVE"  ;;
        WARNING|DEGRADED|SLOW)  color="$C_YELLOW" ; state="WARNING" ;;
        OFFLINE|DOWN|STOPPED|ERROR|FAIL) color="$C_RED"; state="OFFLINE" ;;
        *)                      color="$C_GRAY"   ;;
    esac
    local nlen=${#name}
    local pad=$(( label_w - nlen ))
    (( pad < 0 )) && pad=0
    local body="${C_LABEL}${name}$(printf '%*s' "$pad" '')${RESET} ${color}${DOT}${RESET} ${BOLD}${color}${state}${RESET}"
    ui_card_row "$body"
}

# Menu item row: ui_card_menu "01" "SSH MANAGEMENT"
ui_card_menu() {
    local idx="$1" label="$2"
    local body="${C_GRAY}[${C_PRIMARY_2}${BOLD}${idx}${RESET}${C_GRAY}]${RESET}  ${C_VALUE}${label}${RESET}"
    ui_card_row "$body"
}

# ------------------------------------------------------------
#  NOTIFICATION SYSTEM
# ------------------------------------------------------------
ui_notify_success() { printf '%b ✔ SUCCESS %b %s\n' "${C_GREEN}${BOLD}"   "$RESET" "$*"; }
ui_notify_warning() { printf '%b ⚠ WARNING %b %s\n' "${C_YELLOW}${BOLD}"  "$RESET" "$*"; }
ui_notify_error()   { printf '%b ✘ ERROR   %b %s\n' "${C_RED}${BOLD}"     "$RESET" "$*"; }
ui_notify_info()    { printf '%b ℹ INFO    %b %s\n' "${C_MAGENTA}${BOLD}" "$RESET" "$*"; }

# Boxed notification (used for end-of-action confirmations)
ui_notify_box() {
    local kind="$1"; shift
    local message="$*"
    local icon color label
    case "$kind" in
        success) icon="✔"; color="$C_GREEN";   label="SUCCESS" ;;
        warning) icon="⚠"; color="$C_YELLOW";  label="WARNING" ;;
        error)   icon="✘"; color="$C_RED";     label="ERROR"   ;;
        info|*)  icon="ℹ"; color="$C_MAGENTA"; label="INFO"    ;;
    esac
    local prev_border="$C_BORDER"
    C_BORDER="$color"
    ui_card_top ""
    ui_card_row "${color}${BOLD}${icon}  ${label}${RESET}  ${C_GRAY}—${RESET}  ${C_VALUE}${message}${RESET}"
    ui_card_bottom
    C_BORDER="$prev_border"
}

# ------------------------------------------------------------
#  PROGRESS BAR
#  Usage:
#     ui_progress_run "Installing Xray" 25     # 25 ticks @ ~30ms
#     ui_progress_step "Configuring SSL" 40    # quick step
#     ui_progress_set "Applying BBR" 75        # explicit percent
#     ui_progress_done "All services online"
# ------------------------------------------------------------
__progress_render() {
    local label="$1" percent="$2"
    local bar_len=30
    local filled=$(( percent * bar_len / 100 ))
    (( filled > bar_len )) && filled=$bar_len
    local empty=$(( bar_len - filled ))
    local fill_block empty_block
    fill_block=$(__repeat '█' "$filled")
    empty_block=$(__repeat '░' "$empty")
    # color shifts from cyan -> green as it nears 100
    local color="$C_PRIMARY_2"
    (( percent >= 70 )) && color="$C_GREEN_SOFT"
    (( percent >= 95 )) && color="$C_GREEN"
    printf '\r%b▶%b %-30s %b[%s%s]%b %b%3d%%%b' \
        "$C_PRIMARY" "$RESET" "$label" \
        "$C_GRAY" "${color}${fill_block}" "${C_GRAY}${empty_block}" "$RESET" \
        "${BOLD}${color}" "$percent" "$RESET"
}

# Animate a progress bar from 0 to 100 with the given label
ui_progress_run() {
    local label="${1:-Working}" ticks="${2:-30}"
    local i percent
    for (( i=0; i<=ticks; i++ )); do
        percent=$(( i * 100 / ticks ))
        __progress_render "$label" "$percent"
        sleep 0.03
    done
    printf '\n'
}

# Single quick "step" — shows a one-shot bar at given percent
ui_progress_set() {
    local label="$1" percent="$2"
    __progress_render "$label" "$percent"
    printf '\n'
}

# Final "100%" line + tick
ui_progress_done() {
    local message="${1:-Completed}"
    printf '%b ✔ %s%b\n' "${BOLD}${C_GREEN}" "$message" "$RESET"
}

# ------------------------------------------------------------
#  Screen helpers
# ------------------------------------------------------------
ui_clear() { clear 2>/dev/null || printf '\033[2J\033[H'; }

ui_pause() {
    local msg="${1:-Press [Enter] to continue}"
    printf '\n%b%s%b ' "$C_GRAY" "$msg" "$RESET"
    read -r _ || true
}

# Read user choice with a styled prompt
ui_prompt() {
    local label="${1:-Select option}"
    printf '\n%b┃%b %b%s%b %b▶%b ' \
        "$C_PRIMARY" "$RESET" "${BOLD}${C_VALUE}" "$label" "$RESET" "$C_PRIMARY_2" "$RESET"
}
