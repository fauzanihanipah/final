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

## Layout

```
final/
├── install.sh                # Installer (root, idempotent)
├── menu/
│   ├── lib/
│   │   ├── ui.sh             # Core UI library — all visuals
│   │   ├── sysinfo.sh        # System info gathering
│   │   └── submenu.sh        # Shared submenu runner
│   ├── menu.sh               # Main dashboard entry
│   ├── ssh.sh                # SSH management
│   ├── vmess.sh              # VMESS management
│   ├── vless.sh              # VLESS management
│   ├── trojan.sh             # Trojan management
│   ├── backup.sh             # Backup & Restore
│   ├── monitor.sh            # Monitoring
│   ├── system.sh             # System settings
│   ├── admin.sh              # Admin management
│   ├── update.sh             # Update panel
│   └── VERSION
└── README.md
```

The UI layer (`menu/`) is fully decoupled from the backend.  
Action commands referenced by the menus (`add-ssh`, `del-ssh`,
`add-vm`, `bbr`, `backup`, …) are provided by the companion
binary package: <https://github.com/chanelog/bin>.

If a backend command is missing on the target VPS, the menu
shows a styled `⚠ WARNING` notification and continues — it
will never error or break the dashboard.

## Quick start

```bash
sudo bash install.sh
menu
```

After installation:

| Command   | Opens                |
|-----------|----------------------|
| `menu`    | Main dashboard       |
| `m-ssh`   | SSH submenu          |
| `m-vmess` | VMESS submenu        |
| `m-vless` | VLESS submenu        |
| `m-trojan`| Trojan submenu       |
| `m-backup`| Backup & Restore     |
| `m-monitor`| Live monitoring     |
| `m-system`| System settings      |
| `m-admin` | Admin management     |
| `m-update`| Update panel         |

## Design rules

- UI logic and backend logic are strictly separated.
- No hardcoded spacing — all padding is computed from the
  current terminal width via `tput cols`.
- Every card has identical width (clamped between 64 and 96
  columns) so the dashboard stays symmetric on any terminal.
- All colours come from named variables in `lib/ui.sh`; no
  raw escape codes are scattered through the menus.
