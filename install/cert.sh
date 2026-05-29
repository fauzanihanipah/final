#!/usr/bin/env bash
# ============================================================
#  Domain + TLS certificate management.
#  ----------------------------------------------------------
#  Two entry points:
#
#    dewa_install_cert            — called by run.sh during the
#                                   initial installation. Reads the
#                                   domain from $DEWA_DOMAIN, an
#                                   existing /etc/xray/domain file,
#                                   or by interactive prompt.
#
#    dewa_change_domain [new]     — called by the `change-domain`
#                                   wrapper from the System menu.
#                                   Re-issues the cert and reloads
#                                   nginx + xray.
#
#  Strategy:
#    1. Save the chosen domain to /etc/xray/domain so sys_domain()
#       picks it up across reboots.
#    2. Install acme.sh on first use.
#    3. Issue a Let's Encrypt ECDSA-P256 cert via webroot mode
#       (/var/www/html), which works while nginx keeps serving on
#       port 80 — no downtime.
#    4. Install the cert into /etc/nginx/dewa.{crt,key} and reload
#       nginx. Falls back to the self-signed cert nginx.sh wrote
#       if anything goes wrong, so the panel never breaks.
# ============================================================

DEWA_DOMAIN_FILE=/etc/xray/domain
ACME_HOME=/root/.acme.sh
ACME_BIN="${ACME_HOME}/acme.sh"
NGX_CRT=/etc/nginx/dewa.crt
NGX_KEY=/etc/nginx/dewa.key

# ------------------------------------------------------------
#  Helpers
# ------------------------------------------------------------
__cert_log() {
    if declare -F inst_log >/dev/null 2>&1; then inst_log "$@"
    else printf '[cert] %s\n' "$*"; fi
}

__cert_valid_domain() {
    [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]]
}

# Read domain from $1 (env-or-file priority order).
__cert_resolve_domain() {
    local d="${1:-}"
    [[ -z "$d" ]] && d="${DEWA_DOMAIN:-}"
    [[ -z "$d" && -r "$DEWA_DOMAIN_FILE" ]] && d=$(head -n1 "$DEWA_DOMAIN_FILE" | tr -d '[:space:]')
    printf '%s' "$d"
}

# Prompt the user for a domain. Skips silently when not interactive.
__cert_prompt_domain() {
    [[ -t 0 ]] || return 1
    local input=""
    if declare -F ui_card_top >/dev/null 2>&1; then
        ui_blank
        ui_card_top "DOMAIN SETUP"
        ui_card_row "${C_LABEL}Point an A-record to this VPS first.${RESET}"
        ui_card_row "${C_GRAY}Leave blank to skip and use a self-signed cert.${RESET}"
        ui_card_bottom
    fi
    printf '%bEnter domain (or blank to skip)%b ▶ ' "${BOLD:-}" "${RESET:-}"
    read -r input || return 1
    input="${input// /}"
    [[ -z "$input" ]] && return 1
    if ! __cert_valid_domain "$input"; then
        if declare -F ui_notify_warning >/dev/null 2>&1; then
            ui_notify_warning "Invalid domain: '$input' — skipping TLS provisioning."
        fi
        return 1
    fi
    printf '%s' "$input"
}

__cert_save_domain() {
    local d="$1"
    mkdir -p "$(dirname "$DEWA_DOMAIN_FILE")"
    printf '%s\n' "$d" > "$DEWA_DOMAIN_FILE"
    chmod 644 "$DEWA_DOMAIN_FILE"
    __cert_log "domain saved to $DEWA_DOMAIN_FILE: $d"
}

__cert_acme_install() {
    [[ -x "$ACME_BIN" ]] && return 0
    if ! command -v curl >/dev/null 2>&1; then
        inst_pkg_install curl ca-certificates socat || return 1
    else
        inst_pkg_install socat || true
    fi
    local email="admin@$1"
    if ! inst_run bash -c "curl -fsSL https://get.acme.sh | sh -s email=${email}"; then
        __cert_log "acme.sh install failed"
        return 1
    fi
    return 0
}

__cert_issue() {
    local domain="$1"
    mkdir -p /var/www/html
    [[ -f /var/www/html/index.html ]] || echo "OK" > /var/www/html/index.html

    # Acme.sh switched its default CA to ZeroSSL; pin to Let's Encrypt
    # so existing tooling keeps working.
    inst_run "$ACME_BIN" --set-default-ca --server letsencrypt

    if ! inst_run "$ACME_BIN" --issue \
            -d "$domain" \
            --webroot /var/www/html \
            --keylength ec-256 \
            --force; then
        __cert_log "acme issue failed for $domain"
        return 1
    fi
    return 0
}

__cert_install_to_nginx() {
    local domain="$1"
    if ! inst_run "$ACME_BIN" --install-cert -d "$domain" --ecc \
            --fullchain-file "$NGX_CRT" \
            --key-file "$NGX_KEY" \
            --reloadcmd "systemctl reload nginx 2>/dev/null || systemctl restart nginx"; then
        __cert_log "acme install-cert failed for $domain"
        return 1
    fi
    return 0
}

__cert_update_nginx_servername() {
    local domain="$1"
    local conf=/etc/nginx/conf.d/dewa.conf
    [[ -f "$conf" ]] || return 0
    # Replace `server_name _;` with the real domain so vhost matching works.
    sed -i "s/server_name _;/server_name ${domain};/g" "$conf"
}

# ------------------------------------------------------------
#  Public entry points
# ------------------------------------------------------------
dewa_install_cert() {
    __cert_log "=== CERT / DOMAIN ==="
    local domain
    domain=$(__cert_resolve_domain)

    if [[ -z "$domain" ]]; then
        # Try interactive prompt; if no tty, fall back to self-signed.
        if domain=$(__cert_prompt_domain); then
            :
        else
            __cert_log "no domain provided — keeping self-signed cert"
            __cert_save_domain "not-configured"
            return 0
        fi
    fi

    __cert_save_domain "$domain"

    if ! __cert_acme_install "$domain"; then
        if declare -F ui_notify_warning >/dev/null 2>&1; then
            ui_notify_warning "acme.sh install failed — keeping self-signed cert."
        fi
        return 0
    fi

    if ! __cert_issue "$domain"; then
        if declare -F ui_notify_warning >/dev/null 2>&1; then
            ui_notify_warning "Could not issue Let's Encrypt cert (DNS not propagated?). Keeping self-signed."
        fi
        return 0
    fi

    if ! __cert_install_to_nginx "$domain"; then
        if declare -F ui_notify_warning >/dev/null 2>&1; then
            ui_notify_warning "Cert issued but failed to install into nginx. Run change-domain later."
        fi
        return 0
    fi

    __cert_update_nginx_servername "$domain"
    inst_run systemctl reload nginx || inst_run systemctl restart nginx
    inst_run systemctl restart xray

    if declare -F ui_notify_success >/dev/null 2>&1; then
        ui_notify_success "TLS certificate issued for ${domain}"
    fi
    return 0
}

dewa_change_domain() {
    # When called from the menu we usually have a tty.
    local new="${1:-}"
    if [[ -z "$new" ]] && [[ -t 0 ]]; then
        printf 'New domain ▶ '
        read -r new
        new="${new// /}"
    fi
    if [[ -z "$new" ]]; then
        echo "Aborted: no domain given." >&2
        return 1
    fi
    if ! __cert_valid_domain "$new"; then
        echo "Invalid domain: $new" >&2
        return 1
    fi
    DEWA_DOMAIN="$new"
    dewa_install_cert
}

# Allow this file to be executed directly (used by the change-domain wrapper).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Source common.sh + ui.sh from the standard install location.
    if [[ -f /opt/dewa-panel/install/common.sh ]]; then
        # shellcheck disable=SC1091
        source /opt/dewa-panel/install/common.sh
    fi
    if [[ -f /opt/dewa-panel/menu/lib/ui.sh ]]; then
        # shellcheck disable=SC1091
        source /opt/dewa-panel/menu/lib/ui.sh
    fi

    case "${1:-change}" in
        change|set) shift; dewa_change_domain "$@" ;;
        install)    dewa_install_cert ;;
        renew)
            domain=$(__cert_resolve_domain)
            [[ -z "$domain" ]] && { echo "No domain configured."; exit 1; }
            inst_run "$ACME_BIN" --renew -d "$domain" --ecc --force
            ;;
        *)
            echo "usage: $0 {change|install|renew}" >&2
            exit 2
            ;;
    esac
fi
