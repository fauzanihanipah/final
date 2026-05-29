#!/usr/bin/env bash
# ============================================================
#  Self-update for the DEWA TUNNELING PANEL.
#  ----------------------------------------------------------
#  Maintains a clone at $UPDATE_SRC, pulls the latest changes,
#  and re-runs install.sh from that clone. The installer is
#  idempotent so this is safe to run anytime.
#
#  Invoked via the `update-panel` CLI wrapper or from the
#  Update submenu (option [02]).
# ============================================================

UPDATE_SRC="${DEWA_UPDATE_SRC:-/opt/dewa-panel-src}"
UPDATE_REPO="${DEWA_REPO:-https://github.com/fauzanihanipah/final}"
UPDATE_BRANCH="${DEWA_BRANCH:-main}"

dewa_update_panel() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        echo "update-panel must run as root (try: sudo update-panel)" >&2
        return 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get -qq update >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get -y -qq install git ca-certificates >/dev/null 2>&1 || true
        elif command -v dnf >/dev/null 2>&1; then dnf install -y git ca-certificates >/dev/null 2>&1 || true
        elif command -v yum >/dev/null 2>&1; then yum install -y git ca-certificates >/dev/null 2>&1 || true
        elif command -v apk >/dev/null 2>&1; then apk add --no-cache git ca-certificates >/dev/null 2>&1 || true
        fi
    fi
    command -v git >/dev/null 2>&1 || { echo "git is required to update." >&2; return 1; }

    if [[ -d "${UPDATE_SRC}/.git" ]]; then
        git -C "$UPDATE_SRC" remote set-url origin "$UPDATE_REPO" 2>/dev/null || true
        git -C "$UPDATE_SRC" fetch --depth 1 origin "$UPDATE_BRANCH" || return 1
        git -C "$UPDATE_SRC" reset --hard "origin/$UPDATE_BRANCH"  || return 1
    else
        rm -rf "$UPDATE_SRC"
        git clone --depth 1 -b "$UPDATE_BRANCH" "$UPDATE_REPO" "$UPDATE_SRC" || return 1
    fi

    exec bash "${UPDATE_SRC}/install.sh"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    dewa_update_panel
fi
