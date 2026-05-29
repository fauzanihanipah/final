# DEWA TUNNELING PANEL — Enterprise Edition

A premium, commercial-grade terminal dashboard for tunneling / VPN VPS
management. The panel focuses on a clean, symmetrical, colour-rich UI
that auto-adapts to terminal width (80–200 columns).

## Visual standards

- Unicode box drawing (rounded cards · double-line banners)
- ANSI 256-colour palette with named colour variables
- Gradient header (blue → cyan), per-character interpolation
- Centered headers with automatic padding
- Status dots: ● green = active · yellow = warning · red = offline
- Notifications: ✔ SUCCESS · ⚠ WARNING · ✘ ERROR · ℹ INFO
- Animated progress bars with real-time labels

## Quick start

One-liner (works on a fresh Ubuntu 22.04 / Debian 12 VPS, run as root):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fauzanihanipah/final/main/install.sh)
```

You'll be prompted for a domain (point an A-record at the VPS first).
Press Enter to skip and start with a self-signed cert — you can set
the domain later from the menu.

Non-interactive install (CI / scripted):

```bash
DEWA_DOMAIN=vpn.example.com bash <(curl -fsSL https://raw.githubusercontent.com/fauzanihanipah/final/main/install.sh)
```

After install, type `menu` to launch the dashboard.

## Layout

```
final/
├── install.sh                  # Top-level installer (root, idempotent)
├── install/                    # Backend service installers
│   ├── common.sh               # Shared helpers (logging, pkg-mgr, systemd, certs)
│   ├── run.sh                  # Service orchestrator
│   ├── bbr.sh                  # BBR + TCP tuning (sysctl)
│   ├── ipv6.sh                 # Disable IPv6 (sysctl)
│   ├── ssh.sh                  # OpenSSH (ports 22, 444)
│   ├── dropbear.sh             # Dropbear (ports 109, 143, 80)
│   ├── stunnel.sh              # Stunnel + stunnel5 alias unit
│   ├── nginx.sh                # Nginx (port 80 ACME + port 443 TLS)
│   ├── xray.sh                 # Xray-core: vmess + vless + trojan over WS
│   ├── badvpn.sh               # BadVPN-udpgw (7100/7200/7300 udp)
│   ├── fail2ban.sh             # Fail2ban (sshd + dropbear jails)
│   ├── slowdns.sh              # SlowDNS placeholder
│   ├── cert.sh                 # Domain + Let's Encrypt (acme.sh)
│   └── update.sh               # Self-update from GitHub
├── menu/
│   ├── lib/
│   │   ├── ui.sh               # Core UI library
│   │   ├── sysinfo.sh          # System info gathering
│   │   └── submenu.sh          # Shared submenu runner
│   ├── menu.sh                 # Main dashboard
│   ├── ssh.sh / vmess.sh / vless.sh / trojan.sh
│   ├── backup.sh / monitor.sh / system.sh / admin.sh / update.sh
│   └── VERSION
└── README.md
```

## CLI commands installed by `install.sh`

| Command          | Action                                           |
|------------------|--------------------------------------------------|
| `menu`           | Open the main dashboard                          |
| `m-ssh` … `m-update` | Open a specific submenu directly             |
| `update-panel`   | Pull latest from GitHub & re-run install.sh      |
| `change-domain`  | Set / replace domain + Let's Encrypt cert        |
| `renew-cert`     | Force renew the existing Let's Encrypt cert      |

All commands are idempotent.

## Updating an existing install

Three equivalent options:

```bash
# 1. From inside the panel:    menu → [09] UPDATE PANEL → [02] Update Panel Now
# 2. From the shell:
update-panel

# 3. Re-run the installer one-liner (always safe):
bash <(curl -fsSL https://raw.githubusercontent.com/fauzanihanipah/final/main/install.sh)
```

`update-panel` keeps a working clone at `/opt/dewa-panel-src` and
re-runs `install.sh` from it; subsequent updates are fast (shallow
fetch + reset --hard).

## Domain & TLS

The installer asks for a domain on first run. To set or change it
afterwards:

```bash
change-domain                        # interactive prompt
change-domain vpn.example.com        # one-shot
```

This will:

1. Save the domain to `/etc/xray/domain` (so the dashboard reflects it).
2. Install acme.sh on first use (~/.acme.sh).
3. Issue a Let's Encrypt ECDSA-P256 cert via webroot mode
   (`/var/www/html`), no nginx downtime.
4. Install the cert into `/etc/nginx/dewa.{crt,key}`.
5. Reload nginx and restart Xray.

If validation fails (DNS not propagated yet, port 80 blocked, …) the
panel keeps the existing self-signed cert and prints a clear warning —
your services stay online. Re-run `change-domain` after fixing DNS.

Renewals are automatic (acme.sh installs a daily cron). Force a renew
with `renew-cert`.

## Design rules

- UI logic and backend logic are strictly separated.
- No hardcoded spacing — all padding is computed from the current
  terminal width via `tput cols`.
- Every card has identical width (clamped between 64 and 96 columns)
  so the dashboard stays symmetric on any terminal.
- All colours come from named variables in `lib/ui.sh`; no raw escape
  codes are scattered through the menus.
- Every install module is idempotent and logs to
  `/var/log/dewa-install.log`.

## Environment variables

| Variable        | Default                                     | Purpose                       |
|-----------------|---------------------------------------------|-------------------------------|
| `DEWA_REPO`     | `https://github.com/fauzanihanipah/final`   | Source repo for bootstrap & update |
| `DEWA_BRANCH`   | `main`                                      | Branch to install / update from |
| `DEWA_DOMAIN`   | (prompt)                                    | Domain for Let's Encrypt      |
| `DEWA_UPDATE_SRC` | `/opt/dewa-panel-src`                     | Working clone for `update-panel` |
