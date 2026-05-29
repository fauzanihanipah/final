#!/usr/bin/env bash
# ============================================================
#  DEWA TUNNELING PANEL — Installer
#  ----------------------------------------------------------
#  Works in three invocation modes:
#    1.  bash install.sh                  (run from a clone)
#    2.  bash <(curl -fsSL …/install.sh)  (process substitution)
#    3.  curl -fsSL … | bash              (piped to bash)
#
#  In modes 2 and 3 the script lives in /dev/fd/* or stdin, so the
#  adjacent menu/ directory is not available. The bootstrap block
#  below detects this and clones the repo to a temp dir before the
#  UI library is sourced.
# ============================================================

set -u

# ------------------------------------------------------------
#  Bootstrap (no UI library yet — use plain output only)
# ------------------------------------------------------------
__boot_die() {
    printf '\033[1;31m✘ ERROR\033[0m  %s\n' "$*" >&2
    exit 1
}
__boot_info() {
    printf '\033[1;36mℹ INFO\033[0m   %s\n' "$*"
}

# Root check happens early because both the bootstrap (apt install git)
# and the install itself require root privileges.
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    __boot_die "This installer must be run as root. Try: sudo bash install.sh"
fi

__BOOTSTRAPPED=0
__detect_src_dir() {
    local self="${BASH_SOURCE[0]}"
    local dir=""
    if [[ -n "$self" ]]; then
        dir="$( cd "$( dirname "$self" )" 2>/dev/null && pwd )" || dir=""
    fi
    # Happy path: we're running from a checkout that already contains menu/.
    if [[ -n "$dir" && -d "$dir/menu" && -f "$dir/menu/lib/ui.sh" ]]; then
        printf '%s' "$dir"
        return
    fi

    # Bootstrap path: install git if missing, then clone the repo.
    __boot_info "Installer running without local files — bootstrapping from GitHub…" >&2

    if ! command -v git >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get -qq update >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get -y -qq install git ca-certificates curl >/dev/null 2>&1 || true
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y git ca-certificates curl >/dev/null 2>&1 || true
        elif command -v yum >/dev/null 2>&1; then
            yum install -y git ca-certificates curl >/dev/null 2>&1 || true
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache git ca-certificates curl >/dev/null 2>&1 || true
        fi
    fi
    command -v git >/dev/null 2>&1 \
        || __boot_die "git is required to bootstrap but could not be installed automatically."

    local repo="${DEWA_REPO:-https://github.com/fauzanihanipah/final}"
    local branch="${DEWA_BRANCH:-main}"
    local tmp
    tmp=$(mktemp -d -t dewa-panel.XXXXXX) \
        || __boot_die "could not create temporary directory"

    if ! git clone --depth 1 -b "$branch" "$repo" "$tmp" >/dev/null 2>&1; then
        rm -rf "$tmp"
        __boot_die "failed to clone $repo (branch: $branch)"
    fi
    if [[ ! -f "$tmp/menu/lib/ui.sh" ]]; then
        rm -rf "$tmp"
        __boot_die "cloned repository does not contain menu/lib/ui.sh"
    fi
    __BOOTSTRAPPED=1
    printf '%s' "$tmp"
}

SRC_DIR="$(__detect_src_dir)"
INSTALL_DIR="/opt/dewa-panel"
BIN_DIR="/usr/local/sbin"
BIN_REPO_URL="https://github.com/chanelog/bin"

# Clean up bootstrap clone on exit (success or failure).
trap '[[ "${__BOOTSTRAPPED:-0}" == "1" && -n "${SRC_DIR:-}" && "$SRC_DIR" == /tmp/* ]] && rm -rf "$SRC_DIR"' EXIT

# Now that SRC_DIR is guaranteed valid, source the UI library.
# shellcheck source=menu/lib/ui.sh
source "${SRC_DIR}/menu/lib/ui.sh"

# ------------------------------------------------------------
#  Installer steps (use the styled UI library from here on)
# ------------------------------------------------------------
step() {
    local label="$1" pct="$2"
    ui_progress_set "$label" "$pct"
}

check_os() {
    if [[ ! -r /etc/os-release ]]; then
        ui_notify_warning "Could not detect OS — proceeding anyway."
        return
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
        ubuntu|debian) ui_notify_success "Detected ${PRETTY_NAME}" ;;
        *)             ui_notify_warning "Untested OS: ${PRETTY_NAME:-unknown} — install will continue." ;;
    esac
}

ensure_deps() {
    local pkgs=(curl wget jq unzip git ca-certificates)
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get -qq update >/dev/null 2>&1 || true
        DEBIAN_FRONTEND=noninteractive apt-get -y -qq install "${pkgs[@]}" >/dev/null 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "${pkgs[@]}" >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "${pkgs[@]}" >/dev/null 2>&1 || true
    fi
}

copy_panel() {
    mkdir -p "$INSTALL_DIR"
    # Remove any old menu/ so re-running the installer always lands clean.
    rm -rf "${INSTALL_DIR}/menu" "${INSTALL_DIR}/install"
    cp -r "${SRC_DIR}/menu" "${INSTALL_DIR}/"
    [[ -d "${SRC_DIR}/install" ]] && cp -r "${SRC_DIR}/install" "${INSTALL_DIR}/"
    cp    "${SRC_DIR}/install.sh" "${INSTALL_DIR}/" 2>/dev/null || true
    chmod -R 0755 "${INSTALL_DIR}/menu"
    [[ -d "${INSTALL_DIR}/install" ]] && chmod -R 0755 "${INSTALL_DIR}/install"
    find "${INSTALL_DIR}/menu" -name '*.sh' -exec chmod +x {} +
    [[ -d "${INSTALL_DIR}/install" ]] && find "${INSTALL_DIR}/install" -name '*.sh' -exec chmod +x {} +
}

install_wrappers() {
    mkdir -p "$BIN_DIR"
    # Main entry — `menu` opens the dashboard.
    cat > "${BIN_DIR}/menu" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/menu/menu.sh" "\$@"
EOF
    chmod +x "${BIN_DIR}/menu"

    # Convenience aliases for each submenu.
    local pair name file
    for pair in \
        "m-ssh:ssh.sh" \
        "m-vmess:vmess.sh" \
        "m-vless:vless.sh" \
        "m-trojan:trojan.sh" \
        "m-backup:backup.sh" \
        "m-monitor:monitor.sh" \
        "m-system:system.sh" \
        "m-admin:admin.sh" \
        "m-update:update.sh" ; do
        name="${pair%%:*}"
        file="${pair##*:}"
        cat > "${BIN_DIR}/${name}" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/menu/${file}" "\$@"
EOF
        chmod +x "${BIN_DIR}/${name}"
    done

    # ---- Backend command wrappers -----------------------------------
    # update-panel  — pulls latest from GitHub and re-runs install.sh.
    cat > "${BIN_DIR}/update-panel" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/install/update.sh" "\$@"
EOF
    chmod +x "${BIN_DIR}/update-panel"

    # change-domain — set/replace the panel's domain + Let's Encrypt cert.
    cat > "${BIN_DIR}/change-domain" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/install/cert.sh" change "\$@"
EOF
    chmod +x "${BIN_DIR}/change-domain"

    # renew-cert — renew the existing Let's Encrypt cert.
    cat > "${BIN_DIR}/renew-cert" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/install/cert.sh" renew "\$@"
EOF
    chmod +x "${BIN_DIR}/renew-cert"

    # dewa-doctor — quick health check.
    cat > "${BIN_DIR}/dewa-doctor" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/install/doctor.sh" "\$@"
EOF
    chmod +x "${BIN_DIR}/dewa-doctor"
}

install_bin_backend() {
    # The actual VPN management binaries live in chanelog/bin.
    # The installer attempts to fetch them but never aborts the
    # panel install if the network is unreachable.
    if ! command -v git >/dev/null 2>&1; then
        ui_notify_warning "git not available — skipping bin backend."
        return
    fi
    local tmp
    tmp=$(mktemp -d)
    if git clone --depth 1 "${BIN_REPO_URL}.git" "$tmp" >/dev/null 2>&1; then
        if [[ -d "${tmp}/bin" ]]; then
            cp -f "${tmp}"/bin/* "${BIN_DIR}/" 2>/dev/null || true
        else
            cp -f "${tmp}"/* "${BIN_DIR}/" 2>/dev/null || true
        fi
        find "${BIN_DIR}" -maxdepth 1 -type f -exec chmod +x {} +
        ui_notify_success "Bin backend installed from chanelog/bin."
    else
        ui_notify_warning "Could not reach ${BIN_REPO_URL} — bin backend not installed."
        ui_notify_info    "You can run this installer again later to fetch it."
    fi
    rm -rf "$tmp"
}

main() {
    ui_clear
    ui_header "DEWA TUNNELING PANEL v5" "INSTALLER · ENTERPRISE EDITION"
    ui_blank

    if (( __BOOTSTRAPPED == 1 )); then
        ui_notify_info "Bootstrapped from GitHub into ${SRC_DIR}"
        ui_blank
    fi

    ui_card_top "PRE-FLIGHT CHECK"
    ui_card_kv "Source"      "$SRC_DIR"      12
    ui_card_kv "Target"      "$INSTALL_DIR"  12
    ui_card_kv "Wrappers"    "$BIN_DIR"      12
    ui_card_kv "Bin Repo"    "$BIN_REPO_URL" 12
    ui_card_bottom
    ui_blank

    check_os
    ui_blank

    step "Installing dependencies"   10 ; ensure_deps
    step "Copying panel files"       30 ; copy_panel
    step "Installing CLI wrappers"   45 ; install_wrappers

    # ---- Install all backend services (xray, dropbear, stunnel, …) ----
    # shellcheck source=install/run.sh
    if [[ -f "${SRC_DIR}/install/run.sh" ]]; then
        ui_blank
        source "${SRC_DIR}/install/run.sh"
        dewa_run_all_services
        ui_blank
    fi

    step "Fetching bin backend"      85 ; install_bin_backend
    step "Finalising installation"  100
    ui_progress_done "Panel installation complete"
    ui_blank

    ui_card_top "INSTALL SUMMARY"
    ui_card_kv "Launch Panel"   "menu"          16
    ui_card_kv "Update Panel"   "update-panel"  16
    ui_card_kv "Change Domain"  "change-domain" 16
    ui_card_kv "Renew TLS Cert" "renew-cert"    16
    ui_card_kv "SSH Submenu"    "m-ssh"         16
    ui_card_kv "VMESS Submenu"  "m-vmess"       16
    ui_card_kv "VLESS Submenu"  "m-vless"       16
    ui_card_kv "Trojan Submenu" "m-trojan"      16
    ui_card_kv "System Submenu" "m-system"      16
    ui_card_kv "Admin Submenu"  "m-admin"       16
    ui_card_kv "Update Submenu" "m-update"      16
    ui_card_bottom
    ui_blank

    ui_notify_box success "Installation finished — type 'menu' to launch the panel."
    ui_blank
    ui_footer
}

main "$@"
