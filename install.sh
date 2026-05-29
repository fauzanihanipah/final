#!/usr/bin/env bash
# ============================================================
#  DEWA TUNNELING PANEL — Installer
#  ----------------------------------------------------------
#  - Verifies system requirements
#  - Copies the panel to /opt/dewa-panel
#  - Installs CLI wrappers into /usr/local/sbin
#  - Optionally pulls the bin backend from chanelog/bin
#  Exits non-zero on fatal errors and prints a styled summary.
# ============================================================

set -u

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR="/opt/dewa-panel"
BIN_DIR="/usr/local/sbin"
BIN_REPO_URL="https://github.com/chanelog/bin"

# shellcheck source=menu/lib/ui.sh
source "${SRC_DIR}/menu/lib/ui.sh"

require_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        ui_notify_error "This installer must be run as root (try: sudo bash install.sh)."
        exit 1
    fi
}

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
    fi
}

copy_panel() {
    mkdir -p "$INSTALL_DIR"
    cp -r "${SRC_DIR}/menu" "${INSTALL_DIR}/"
    cp    "${SRC_DIR}/install.sh" "${INSTALL_DIR}/" 2>/dev/null || true
    chmod -R 0755 "${INSTALL_DIR}/menu"
    find "${INSTALL_DIR}/menu" -name '*.sh' -exec chmod +x {} +
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
    local pair
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
        local name="${pair%%:*}" file="${pair##*:}"
        cat > "${BIN_DIR}/${name}" <<EOF
#!/usr/bin/env bash
exec bash "${INSTALL_DIR}/menu/${file}" "\$@"
EOF
        chmod +x "${BIN_DIR}/${name}"
    done
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

    require_root

    ui_card_top "PRE-FLIGHT CHECK"
    ui_card_kv "Source"      "$SRC_DIR"
    ui_card_kv "Target"      "$INSTALL_DIR"
    ui_card_kv "Wrappers"    "$BIN_DIR"
    ui_card_kv "Bin Repo"    "$BIN_REPO_URL"
    ui_card_bottom
    ui_blank

    check_os
    ui_blank

    step "Installing dependencies"   10 ; ensure_deps
    step "Copying panel files"       40 ; copy_panel
    step "Installing CLI wrappers"   65 ; install_wrappers
    step "Fetching bin backend"      85 ; install_bin_backend
    step "Finalising installation"  100
    ui_progress_done "Panel installation complete"
    ui_blank

    ui_card_top "INSTALL SUMMARY"
    ui_card_kv "Launch Command" "menu"
    ui_card_kv "SSH Submenu"    "m-ssh"
    ui_card_kv "VMESS Submenu"  "m-vmess"
    ui_card_kv "VLESS Submenu"  "m-vless"
    ui_card_kv "Trojan Submenu" "m-trojan"
    ui_card_kv "System Submenu" "m-system"
    ui_card_kv "Admin Submenu"  "m-admin"
    ui_card_kv "Update Submenu" "m-update"
    ui_card_bottom
    ui_blank

    ui_notify_box success "Installation finished — type 'menu' to launch the panel."
    ui_blank
    ui_footer
}

main "$@"
