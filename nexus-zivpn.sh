#!/bin/bash
# ============================================================
#         NEXUS ZIVPN - Full Installer & Manager
#         Coded with ❤️  by NEXUS TEAM
# ============================================================

# ─── PATHS & URLS ────────────────────────────────────────────
BINARY_URL="https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64"
CONFIG_URL="https://github.com/fauzanihanipah/ziv-udp/raw/main/config.json"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/zivpn"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
USER_DB="/etc/zivpn/users.db"
THEME_FILE="/etc/zivpn/theme.conf"
DOMAIN_FILE="/etc/zivpn/domain.conf"
TG_FILE="/etc/zivpn/telegram.conf"
LOG_FILE="/var/log/zivpn.log"

# ─── THEME DEFINITIONS ───────────────────────────────────────
declare -A THEMES
THEMES[default]="cyan"
THEMES[green]="green"
THEMES[blue]="blue"
THEMES[red]="red"
THEMES[yellow]="yellow"
THEMES[rainbow]="rainbow"

# ─── COLOR CODES ─────────────────────────────────────────────
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BG_BLACK='\033[40m'
BG_BLUE='\033[44m'

# ─── RAINBOW COLOR ARRAY ─────────────────────────────────────
RAINBOW=('\033[0;31m' '\033[0;33m' '\033[1;33m' '\033[0;32m' '\033[0;36m' '\033[0;34m' '\033[0;35m')

# ─── LOAD THEME ──────────────────────────────────────────────
load_theme() {
    CURRENT_THEME="default"
    [[ -f "$THEME_FILE" ]] && CURRENT_THEME=$(cat "$THEME_FILE")

    case "$CURRENT_THEME" in
        green)  TC='\033[0;32m'; TC2='\033[1;32m' ;;
        blue)   TC='\033[0;34m'; TC2='\033[1;34m' ;;
        red)    TC='\033[0;31m'; TC2='\033[1;31m' ;;
        yellow) TC='\033[1;33m'; TC2='\033[0;33m' ;;
        rainbow) TC='\033[0;36m'; TC2='\033[0;35m' ;;
        *)      TC='\033[0;36m'; TC2='\033[1;36m' ;;
    esac
}

# ─── RAINBOW TEXT ────────────────────────────────────────────
rainbow_text() {
    local text="$1"
    local i=0
    for ((c=0; c<${#text}; c++)); do
        echo -ne "${RAINBOW[$((i % 7))]}${text:$c:1}"
        ((i++))
    done
    echo -ne "${NC}"
}

# ─── DIVIDER ─────────────────────────────────────────────────
divider() {
    if [[ "$CURRENT_THEME" == "rainbow" ]]; then
        rainbow_text "══════════════════════════════════════════════════════"
        echo
    else
        echo -e "${TC}══════════════════════════════════════════════════════${NC}"
    fi
}

thin_line() {
    echo -e "${DIM}${TC}──────────────────────────────────────────────────────${NC}"
}

# ─── VPS INFO ────────────────────────────────────────────────
get_vps_info() {
    HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
    OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Linux")
    CPU_MODEL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "Unknown")
    CPU_CORES=$(nproc 2>/dev/null || echo "?")
    RAM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/{print $2}' || echo "?")
    RAM_USED=$(free -m 2>/dev/null | awk '/Mem:/{print $3}' || echo "?")
    DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}' || echo "?")
    DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}' || echo "?")
    UPTIME_INFO=$(uptime -p 2>/dev/null || echo "Unknown")
    PUBLIC_IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "Unknown")
    CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "?")
    LOAD_AVG=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo "?")
}

# ─── LOGO ────────────────────────────────────────────────────
show_logo() {
    clear
    load_theme
    get_vps_info
    echo
    if [[ "$CURRENT_THEME" == "rainbow" ]]; then
        rainbow_text "  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗"
        echo
        rainbow_text "  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝"
        echo
        rainbow_text "  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗"
        echo
        rainbow_text "  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║"
        echo
        rainbow_text "  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║"
        echo
        rainbow_text "  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
        echo
        rainbow_text "         ░▒▓  Z I V P N  ▓▒░  by NEXUS TEAM"
        echo
    else
        echo -e "${TC2}${BOLD}  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗${NC}"
        echo -e "${TC2}${BOLD}  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝${NC}"
        echo -e "${TC}${BOLD}  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗${NC}"
        echo -e "${TC}${BOLD}  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║${NC}"
        echo -e "${TC2}${BOLD}  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║${NC}"
        echo -e "${TC2}${BOLD}  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
        echo -e "${WHITE}${BOLD}         ░▒▓  Z I V P N  ▓▒░  by NEXUS TEAM${NC}"
    fi
    echo
    divider
    # ── VPS INFO SECTION ──
    echo -e "  ${TC2}${BOLD}📡 VPS INFORMATION${NC}"
    thin_line
    echo -e "  ${WHITE}🖥  Hostname   ${NC}: ${TC}$HOSTNAME${NC}"
    echo -e "  ${WHITE}🌐 IP Public  ${NC}: ${TC}$PUBLIC_IP${NC}"
    echo -e "  ${WHITE}💿 OS         ${NC}: ${TC}$OS${NC}"
    echo -e "  ${WHITE}⚙️  CPU        ${NC}: ${TC}$CPU_MODEL (${CPU_CORES} Core)${NC}"
    echo -e "  ${WHITE}📊 CPU Usage  ${NC}: ${TC}${CPU_USAGE}%  Load: $LOAD_AVG${NC}"
    echo -e "  ${WHITE}🧠 RAM        ${NC}: ${TC}${RAM_USED}MB / ${RAM_TOTAL}MB${NC}"
    echo -e "  ${WHITE}💾 Disk       ${NC}: ${TC}${DISK_USED} / ${DISK_TOTAL}${NC}"
    echo -e "  ${WHITE}⏱  Uptime     ${NC}: ${TC}$UPTIME_INFO${NC}"
    divider
    echo
}

# ─── INSTALL ZIVPN ───────────────────────────────────────────
install_zivpn() {
    show_logo
    echo -e "  ${TC2}${BOLD}📦 INSTALASI NEXUS ZIVPN${NC}"
    thin_line
    echo

    # Check root
    if [[ $EUID -ne 0 ]]; then
        echo -e "  ${RED}✗ Jalankan sebagai root!${NC}"
        return 1
    fi

    echo -e "  ${CYAN}[1/6]${NC} Membuat direktori..."
    mkdir -p "$CONFIG_DIR"
    touch "$USER_DB" "$LOG_FILE"

    echo -e "  ${CYAN}[2/6]${NC} Mengunduh binary zivpn..."
    if wget -q --show-progress -O "$INSTALL_DIR/zivpn" "$BINARY_URL" 2>&1; then
        chmod +x "$INSTALL_DIR/zivpn"
        echo -e "  ${GREEN}✓ Binary berhasil diunduh${NC}"
    else
        echo -e "  ${RED}✗ Gagal mengunduh binary!${NC}"
        return 1
    fi

    echo -e "  ${CYAN}[3/6]${NC} Mengunduh config.json..."
    if wget -q -O "$CONFIG_DIR/config.json" "$CONFIG_URL" 2>&1; then
        echo -e "  ${GREEN}✓ Config berhasil diunduh${NC}"
    else
        echo -e "  ${RED}✗ Gagal mengunduh config! Membuat config default...${NC}"
        cat > "$CONFIG_DIR/config.json" <<'EOF'
{
  "listen": ":36712",
  "obfs": "nexuszivpn",
  "auth": {
    "mode": "external",
    "config": {
      "cmd": "/etc/zivpn/auth.sh"
    }
  }
}
EOF
    fi

    echo -e "  ${CYAN}[4/6]${NC} Membuat auth script..."
    cat > "$CONFIG_DIR/auth.sh" <<'AUTHEOF'
#!/bin/bash
ADDR=$1
AUTH=$2
USER_DB="/etc/zivpn/users.db"

if grep -q "^${AUTH}:" "$USER_DB" 2>/dev/null; then
    EXPIRY=$(grep "^${AUTH}:" "$USER_DB" | cut -d':' -f2)
    TODAY=$(date +%Y%m%d)
    if [[ "$TODAY" -le "$EXPIRY" ]]; then
        echo "true"
        exit 0
    fi
fi
echo "false"
exit 1
AUTHEOF
    chmod +x "$CONFIG_DIR/auth.sh"

    echo -e "  ${CYAN}[5/6]${NC} Membuat systemd service..."
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=NEXUS ZivPN UDP Service
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/zivpn server --config $CONFIG_DIR/config.json
Restart=on-failure
RestartSec=5
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn --quiet
    systemctl start zivpn

    echo -e "  ${CYAN}[6/6]${NC} Menyiapkan perintah 'menu'..."
    # Copy installer to /usr/local/bin/menu
    cp "$0" /usr/local/bin/menu 2>/dev/null || cp "$(readlink -f "$0")" /usr/local/bin/menu 2>/dev/null
    chmod +x /usr/local/bin/menu

    # Add to bashrc for auto-call shortcut
    if ! grep -q "alias menu=" /root/.bashrc 2>/dev/null; then
        echo 'alias menu="/usr/local/bin/menu"' >> /root/.bashrc
    fi

    # Default theme
    echo "default" > "$THEME_FILE"

    echo
    divider
    if systemctl is-active --quiet zivpn; then
        echo -e "  ${GREEN}${BOLD}✓ NEXUS ZIVPN berhasil diinstall & berjalan!${NC}"
    else
        echo -e "  ${YELLOW}⚠ Terinstall, tapi service belum aktif. Cek: systemctl status zivpn${NC}"
    fi
    divider
    echo
    read -rp "  Tekan ENTER untuk lanjut..." _
}

# ─── SERVICE STATUS ──────────────────────────────────────────
service_status() {
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "${GREEN}● AKTIF${NC}"
    else
        echo -e "${RED}● MATI${NC}"
    fi
}

# ─── ADD USER ────────────────────────────────────────────────
add_user() {
    show_logo
    echo -e "  ${TC2}${BOLD}➕ TAMBAH AKUN UDP ZIVPN${NC}"
    thin_line
    echo

    read -rp "  Username     : " USERNAME
    [[ -z "$USERNAME" ]] && echo -e "  ${RED}✗ Username kosong!${NC}" && sleep 1 && return

    if grep -q "^${USERNAME}:" "$USER_DB" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠ Username sudah ada!${NC}"
        sleep 1; return
    fi

    read -rp "  Password     : " PASSWORD
    [[ -z "$PASSWORD" ]] && echo -e "  ${RED}✗ Password kosong!${NC}" && sleep 1 && return

    read -rp "  Masa Aktif (hari) [default: 30] : " DAYS
    DAYS=${DAYS:-30}
    EXPIRY=$(date -d "+${DAYS} days" +%Y%m%d 2>/dev/null || date -v+${DAYS}d +%Y%m%d)

    # Format: username:expiry:password
    echo "${USERNAME}:${EXPIRY}:${PASSWORD}" >> "$USER_DB"

    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$PUBLIC_IP")
    PORT=$(grep '"listen"' "$CONFIG_DIR/config.json" 2>/dev/null | grep -oP ':\K[0-9]+' || echo "36712")
    OBFS=$(grep '"obfs"' "$CONFIG_DIR/config.json" 2>/dev/null | cut -d'"' -f4 || echo "nexuszivpn")

    echo
    divider
    echo -e "  ${TC2}${BOLD}✓ AKUN BERHASIL DIBUAT${NC}"
    thin_line
    echo -e "  ${WHITE}👤 Username   ${NC}: ${TC}$USERNAME${NC}"
    echo -e "  ${WHITE}🔑 Password   ${NC}: ${TC}$PASSWORD${NC}"
    echo -e "  ${WHITE}📅 Expired    ${NC}: ${TC}$(date -d "$EXPIRY" '+%d-%m-%Y' 2>/dev/null || echo $EXPIRY)${NC}"
    echo -e "  ${WHITE}🌐 Domain/IP  ${NC}: ${TC}$DOMAIN${NC}"
    echo -e "  ${WHITE}🔌 Port       ${NC}: ${TC}$PORT${NC}"
    echo -e "  ${WHITE}🔒 Obfs       ${NC}: ${TC}$OBFS${NC}"
    divider
    echo

    # Notify Telegram
    notify_telegram "➕ AKUN BARU\nUsername: $USERNAME\nExpired: $EXPIRY\nDomain: $DOMAIN:$PORT"

    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── LIST USER ───────────────────────────────────────────────
list_users() {
    show_logo
    echo -e "  ${TC2}${BOLD}📋 DAFTAR AKUN UDP ZIVPN${NC}"
    thin_line
    echo
    printf "  ${TC}%-20s %-12s %-12s${NC}\n" "USERNAME" "EXPIRED" "STATUS"
    thin_line
    TODAY=$(date +%Y%m%d)
    COUNT=0
    while IFS=':' read -r USER EXP PASS; do
        [[ -z "$USER" ]] && continue
        EXP_FMT=$(date -d "$EXP" '+%d-%m-%Y' 2>/dev/null || echo "$EXP")
        if [[ "$TODAY" -le "$EXP" ]]; then
            STATUS="${GREEN}Aktif${NC}"
        else
            STATUS="${RED}Expired${NC}"
        fi
        printf "  %-20s %-12s " "$USER" "$EXP_FMT"
        echo -e "$STATUS"
        ((COUNT++))
    done < "$USER_DB" 2>/dev/null
    echo
    thin_line
    echo -e "  Total Akun: ${TC2}$COUNT${NC}"
    divider
    echo
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── DELETE USER ─────────────────────────────────────────────
delete_user() {
    show_logo
    echo -e "  ${TC2}${BOLD}🗑  HAPUS AKUN UDP ZIVPN${NC}"
    thin_line
    echo
    list_users_simple
    echo
    read -rp "  Username yang dihapus : " USERNAME
    [[ -z "$USERNAME" ]] && return

    if grep -q "^${USERNAME}:" "$USER_DB" 2>/dev/null; then
        sed -i "/^${USERNAME}:/d" "$USER_DB"
        echo -e "  ${GREEN}✓ Akun $USERNAME berhasil dihapus!${NC}"
        notify_telegram "🗑 AKUN DIHAPUS\nUsername: $USERNAME"
    else
        echo -e "  ${RED}✗ Akun tidak ditemukan!${NC}"
    fi
    sleep 1
}

list_users_simple() {
    echo -e "  ${TC}Akun yang tersedia:${NC}"
    while IFS=':' read -r USER EXP PASS; do
        [[ -z "$USER" ]] && continue
        echo -e "  - $USER"
    done < "$USER_DB" 2>/dev/null
}

# ─── RENEW USER ──────────────────────────────────────────────
renew_user() {
    show_logo
    echo -e "  ${TC2}${BOLD}🔄 PERPANJANG AKUN${NC}"
    thin_line
    echo
    list_users_simple
    echo
    read -rp "  Username     : " USERNAME
    [[ -z "$USERNAME" ]] && return

    if ! grep -q "^${USERNAME}:" "$USER_DB" 2>/dev/null; then
        echo -e "  ${RED}✗ Akun tidak ditemukan!${NC}"
        sleep 1; return
    fi

    read -rp "  Tambah hari  : " DAYS
    DAYS=${DAYS:-30}
    OLD_EXP=$(grep "^${USERNAME}:" "$USER_DB" | cut -d':' -f2)
    NEW_EXP=$(date -d "${OLD_EXP}+${DAYS}days" +%Y%m%d 2>/dev/null || echo "$OLD_EXP")

    PASS=$(grep "^${USERNAME}:" "$USER_DB" | cut -d':' -f3)
    sed -i "s/^${USERNAME}:.*/${USERNAME}:${NEW_EXP}:${PASS}/" "$USER_DB"

    echo -e "  ${GREEN}✓ Akun diperpanjang sampai: $(date -d "$NEW_EXP" '+%d-%m-%Y' 2>/dev/null || echo $NEW_EXP)${NC}"
    notify_telegram "🔄 AKUN DIPERPANJANG\nUsername: $USERNAME\nExpired baru: $NEW_EXP"
    sleep 1
}

# ─── DOMAIN MENU ─────────────────────────────────────────────
domain_menu() {
    while true; do
        show_logo
        echo -e "  ${TC2}${BOLD}🌐 PENGATURAN DOMAIN${NC}"
        thin_line
        echo
        CURRENT_DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Belum diatur")
        echo -e "  Domain saat ini : ${TC}$CURRENT_DOMAIN${NC}"
        echo
        echo -e "  ${TC}[1]${NC} Ganti / Set Domain"
        echo -e "  ${TC}[2]${NC} Hapus Domain (gunakan IP)"
        echo -e "  ${TC}[3]${NC} Cek DNS Domain"
        echo -e "  ${TC}[0]${NC} Kembali"
        echo
        read -rp "  Pilih [0-3] : " OPT
        case $OPT in
            1)
                echo
                read -rp "  Masukkan domain baru : " NEW_DOMAIN
                [[ -z "$NEW_DOMAIN" ]] && continue
                echo "$NEW_DOMAIN" > "$DOMAIN_FILE"
                echo -e "  ${GREEN}✓ Domain diset ke: $NEW_DOMAIN${NC}"
                sleep 1
                ;;
            2)
                rm -f "$DOMAIN_FILE"
                echo -e "  ${GREEN}✓ Domain dihapus, menggunakan IP${NC}"
                sleep 1
                ;;
            3)
                echo
                read -rp "  Domain yang dicek : " CHK_DOMAIN
                echo -e "  ${TC}DNS Result:${NC}"
                nslookup "$CHK_DOMAIN" 2>/dev/null || host "$CHK_DOMAIN" 2>/dev/null || echo "  nslookup tidak tersedia"
                echo
                read -rp "  ENTER untuk lanjut..." _
                ;;
            0) break ;;
        esac
    done
}

# ─── SERVICE MENU ────────────────────────────────────────────
service_menu() {
    while true; do
        show_logo
        echo -e "  ${TC2}${BOLD}⚙️  MANAJEMEN SERVICE${NC}"
        thin_line
        echo
        echo -e "  Status  : $(service_status)"
        echo
        echo -e "  ${TC}[1]${NC} Start Service"
        echo -e "  ${TC}[2]${NC} Stop Service"
        echo -e "  ${TC}[3]${NC} Restart Service"
        echo -e "  ${TC}[4]${NC} Lihat Log"
        echo -e "  ${TC}[5]${NC} Cek Status Detail"
        echo -e "  ${TC}[0]${NC} Kembali"
        echo
        read -rp "  Pilih [0-5] : " OPT
        case $OPT in
            1) systemctl start zivpn && echo -e "  ${GREEN}✓ Service distart${NC}" ;;
            2) systemctl stop zivpn && echo -e "  ${YELLOW}✓ Service distop${NC}" ;;
            3) systemctl restart zivpn && echo -e "  ${GREEN}✓ Service direstart${NC}" ;;
            4) echo; tail -n 30 "$LOG_FILE" 2>/dev/null || echo "  Log kosong"; echo; read -rp "  ENTER..." _ ;;
            5) echo; systemctl status zivpn; echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
        sleep 1
    done
}

# ─── THEME MENU ──────────────────────────────────────────────
theme_menu() {
    while true; do
        show_logo
        echo -e "  ${TC2}${BOLD}🎨 PILIH TEMA${NC}"
        thin_line
        echo
        echo -e "  Tema aktif : ${TC2}${CURRENT_THEME}${NC}"
        echo
        echo -e "  ${CYAN}[1]${NC} 🔵 Default (Cyan)"
        echo -e "  ${GREEN}[2]${NC} 🟢 Green"
        echo -e "  ${BLUE}[3]${NC} 🔷 Blue"
        echo -e "  ${RED}[4]${NC} 🔴 Red"
        echo -e "  ${YELLOW}[5]${NC} 🟡 Yellow"
        echo -ne "  "; rainbow_text "[6] 🌈 Rainbow Pelangi ✨"; echo
        echo -e "  ${DIM}[0]${NC} Kembali"
        echo
        read -rp "  Pilih tema [0-6] : " OPT
        case $OPT in
            1) echo "default" > "$THEME_FILE" ;;
            2) echo "green" > "$THEME_FILE" ;;
            3) echo "blue" > "$THEME_FILE" ;;
            4) echo "red" > "$THEME_FILE" ;;
            5) echo "yellow" > "$THEME_FILE" ;;
            6) echo "rainbow" > "$THEME_FILE" ;;
            0) break ;;
        esac
        load_theme
        [[ "$OPT" -ge 1 && "$OPT" -le 6 ]] && echo -e "  ${GREEN}✓ Tema berhasil diganti!${NC}" && sleep 1
    done
}

# ─── TELEGRAM BOT ────────────────────────────────────────────
telegram_menu() {
    while true; do
        show_logo
        echo -e "  ${TC2}${BOLD}🤖 INTEGRASI TELEGRAM BOT${NC}"
        thin_line
        echo
        TG_TOKEN=$(grep 'TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        TG_CHATID=$(grep 'CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        echo -e "  Bot Token : ${TC}${TG_TOKEN:-Belum diatur}${NC}"
        echo -e "  Chat ID   : ${TC}${TG_CHATID:-Belum diatur}${NC}"
        echo
        echo -e "  ${TC}[1]${NC} Set Bot Token"
        echo -e "  ${TC}[2]${NC} Set Chat ID"
        echo -e "  ${TC}[3]${NC} Test Koneksi Bot"
        echo -e "  ${TC}[4]${NC} Kirim Laporan VPS ke Telegram"
        echo -e "  ${TC}[5]${NC} Hapus Konfigurasi"
        echo -e "  ${TC}[0]${NC} Kembali"
        echo
        read -rp "  Pilih [0-5] : " OPT
        case $OPT in
            1)
                echo
                read -rp "  Masukkan Bot Token : " TOKEN
                [[ -z "$TOKEN" ]] && continue
                # Update or write token
                if [[ -f "$TG_FILE" ]]; then
                    sed -i "s/^TOKEN=.*/TOKEN=$TOKEN/" "$TG_FILE" 2>/dev/null || echo "TOKEN=$TOKEN" >> "$TG_FILE"
                else
                    echo "TOKEN=$TOKEN" > "$TG_FILE"
                fi
                grep -q "^TOKEN=" "$TG_FILE" || echo "TOKEN=$TOKEN" >> "$TG_FILE"
                echo -e "  ${GREEN}✓ Token disimpan${NC}"; sleep 1
                ;;
            2)
                echo
                read -rp "  Masukkan Chat ID : " CHATID
                [[ -z "$CHATID" ]] && continue
                if [[ -f "$TG_FILE" ]]; then
                    grep -q "^CHATID=" "$TG_FILE" && sed -i "s/^CHATID=.*/CHATID=$CHATID/" "$TG_FILE" || echo "CHATID=$CHATID" >> "$TG_FILE"
                else
                    echo "CHATID=$CHATID" >> "$TG_FILE"
                fi
                echo -e "  ${GREEN}✓ Chat ID disimpan${NC}"; sleep 1
                ;;
            3)
                notify_telegram "✅ Test koneksi dari NEXUS ZIVPN berhasil!\nHost: $(hostname)\nIP: $PUBLIC_IP"
                echo -e "  ${GREEN}✓ Pesan test dikirim (cek Telegram)${NC}"; sleep 2
                ;;
            4)
                MSG="📊 *LAPORAN VPS - NEXUS ZIVPN*
Host: $HOSTNAME
IP: $PUBLIC_IP
OS: $OS
RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB
Disk: $DISK_USED / $DISK_TOTAL
Uptime: $UPTIME_INFO
Service: $(systemctl is-active zivpn 2>/dev/null)"
                notify_telegram "$MSG"
                echo -e "  ${GREEN}✓ Laporan dikirim ke Telegram${NC}"; sleep 2
                ;;
            5)
                rm -f "$TG_FILE"
                echo -e "  ${YELLOW}✓ Konfigurasi Telegram dihapus${NC}"; sleep 1
                ;;
            0) break ;;
        esac
    done
}

# ─── TELEGRAM NOTIFY FUNCTION ────────────────────────────────
notify_telegram() {
    local MSG="$1"
    [[ ! -f "$TG_FILE" ]] && return
    local TOKEN=$(grep 'TOKEN=' "$TG_FILE" | cut -d'=' -f2)
    local CHATID=$(grep 'CHATID=' "$TG_FILE" | cut -d'=' -f2)
    [[ -z "$TOKEN" || -z "$CHATID" ]] && return
    curl -s --max-time 5 -X POST \
        "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHATID}" \
        -d "text=${MSG}" \
        -d "parse_mode=Markdown" > /dev/null 2>&1 &
}

# ─── UPDATE ZIVPN ────────────────────────────────────────────
update_zivpn() {
    show_logo
    echo -e "  ${TC2}${BOLD}🔄 UPDATE NEXUS ZIVPN${NC}"
    thin_line
    echo
    echo -e "  ${CYAN}Mengunduh versi terbaru...${NC}"
    if wget -q --show-progress -O "/tmp/zivpn-new" "$BINARY_URL" 2>&1; then
        systemctl stop zivpn 2>/dev/null
        mv "/tmp/zivpn-new" "$INSTALL_DIR/zivpn"
        chmod +x "$INSTALL_DIR/zivpn"
        systemctl start zivpn
        echo -e "  ${GREEN}✓ Update berhasil!${NC}"
    else
        echo -e "  ${RED}✗ Gagal mengunduh update${NC}"
    fi
    sleep 2
}

# ─── UNINSTALL ───────────────────────────────────────────────
uninstall_zivpn() {
    show_logo
    echo -e "  ${RED}${BOLD}⚠  UNINSTALL NEXUS ZIVPN${NC}"
    thin_line
    echo
    echo -e "  ${YELLOW}Semua akun dan konfigurasi akan DIHAPUS!${NC}"
    echo
    read -rp "  Ketik 'HAPUS' untuk konfirmasi: " CONFIRM
    if [[ "$CONFIRM" == "HAPUS" ]]; then
        systemctl stop zivpn 2>/dev/null
        systemctl disable zivpn 2>/dev/null
        rm -f "$SERVICE_FILE" "$INSTALL_DIR/zivpn" /usr/local/bin/menu
        rm -rf "$CONFIG_DIR"
        systemctl daemon-reload
        echo -e "  ${GREEN}✓ NEXUS ZIVPN berhasil diuninstall${NC}"
    else
        echo -e "  ${YELLOW}Uninstall dibatalkan${NC}"
    fi
    sleep 2
}

# ─── REINSTALL BINARY ────────────────────────────────────────
reinstall_binary() {
    show_logo
    echo -e "  ${TC2}${BOLD}🔧 REINSTALL BINARY ZIVPN${NC}"
    thin_line
    echo
    echo -e "  ${YELLOW}Fitur ini akan mengunduh ulang binary zivpn${NC}"
    echo -e "  ${YELLOW}dari GitHub dan mengganti binary yang ada.${NC}"
    echo -e "  ${DIM}Akun & konfigurasi TIDAK akan terhapus.${NC}"
    echo
    echo -e "  ${TC}[1]${NC} Reinstall binary saja"
    echo -e "  ${TC}[2]${NC} Reinstall binary + reset config.json"
    echo -e "  ${TC}[0]${NC} Batal"
    echo
    read -rp "  Pilih [0-2] : " OPT

    case $OPT in
        0) return ;;
        1|2)
            echo
            echo -e "  ${CYAN}[1/3]${NC} Menghentikan service..."
            systemctl stop zivpn 2>/dev/null
            sleep 1

            echo -e "  ${CYAN}[2/3]${NC} Mengunduh ulang binary dari GitHub..."
            if wget -q --show-progress -O "/tmp/zivpn-reinstall" "$BINARY_URL" 2>&1; then
                # Backup binary lama
                [[ -f "$INSTALL_DIR/zivpn" ]] && cp "$INSTALL_DIR/zivpn" "$INSTALL_DIR/zivpn.bak"
                mv "/tmp/zivpn-reinstall" "$INSTALL_DIR/zivpn"
                chmod +x "$INSTALL_DIR/zivpn"
                echo -e "  ${GREEN}  ✓ Binary berhasil diunduh ulang${NC}"
                echo -e "  ${DIM}  (backup disimpan di $INSTALL_DIR/zivpn.bak)${NC}"
            else
                echo -e "  ${RED}  ✗ Gagal mengunduh binary!${NC}"
                echo -e "  ${YELLOW}  Mencoba memulihkan backup...${NC}"
                [[ -f "$INSTALL_DIR/zivpn.bak" ]] && mv "$INSTALL_DIR/zivpn.bak" "$INSTALL_DIR/zivpn"
                systemctl start zivpn 2>/dev/null
                sleep 2; return
            fi

            if [[ "$OPT" == "2" ]]; then
                echo -e "  ${CYAN}     ${NC} Mengunduh ulang config.json..."
                [[ -f "$CONFIG_DIR/config.json" ]] && cp "$CONFIG_DIR/config.json" "$CONFIG_DIR/config.json.bak"
                if wget -q -O "$CONFIG_DIR/config.json" "$CONFIG_URL" 2>&1; then
                    echo -e "  ${GREEN}  ✓ Config berhasil diunduh ulang${NC}"
                    echo -e "  ${DIM}  (backup disimpan di $CONFIG_DIR/config.json.bak)${NC}"
                else
                    echo -e "  ${YELLOW}  ⚠ Gagal unduh config, menggunakan yang lama${NC}"
                    [[ -f "$CONFIG_DIR/config.json.bak" ]] && cp "$CONFIG_DIR/config.json.bak" "$CONFIG_DIR/config.json"
                fi
            fi

            echo -e "  ${CYAN}[3/3]${NC} Menjalankan ulang service..."
            systemctl start zivpn 2>/dev/null
            sleep 1

            echo
            divider
            if systemctl is-active --quiet zivpn 2>/dev/null; then
                echo -e "  ${GREEN}${BOLD}✓ Reinstall selesai! Service berjalan normal.${NC}"
            else
                echo -e "  ${YELLOW}⚠ Reinstall selesai, tapi service tidak aktif.${NC}"
                echo -e "  ${DIM}  Cek: systemctl status zivpn${NC}"
            fi
            divider
            ;;
    esac
    echo
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── MAIN MENU ───────────────────────────────────────────────
main_menu() {
    while true; do
        show_logo
        echo -e "  ${TC2}${BOLD}📌 MENU UTAMA${NC}"
        thin_line
        echo -e "  Status Service : $(service_status)"
        thin_line
        echo
        echo -e "  ${TC}[1]${NC}  📦  Install NEXUS ZIVPN"
        echo -e "  ${TC}[2]${NC}  ➕  Tambah Akun"
        echo -e "  ${TC}[3]${NC}  📋  List Akun"
        echo -e "  ${TC}[4]${NC}  🗑   Hapus Akun"
        echo -e "  ${TC}[5]${NC}  🔄  Perpanjang Akun"
        echo
        echo -e "  ${TC}[6]${NC}  🌐  Pengaturan Domain"
        echo -e "  ${TC}[7]${NC}  ⚙️   Manajemen Service"
        echo -e "  ${TC}[8]${NC}  🤖  Telegram Bot"
        echo -e "  ${TC}[9]${NC}  🎨  Pilih Tema"
        echo
        echo -e "  ${TC}[10]${NC} 🔄  Update ZivPN"
        echo -e "  ${TC}[11]${NC} 📊  Info VPS Lengkap"
        echo -e "  ${TC}[12]${NC} 🔧  Reinstall Binary"
        echo -e "  ${TC}[13]${NC} ❌  Uninstall"
        echo
        thin_line
        echo -e "  ${DIM}[0]  Keluar${NC}"
        echo
        read -rp "  Pilih menu [0-13] : " CHOICE
        case $CHOICE in
            1)  install_zivpn ;;
            2)  add_user ;;
            3)  list_users ;;
            4)  delete_user ;;
            5)  renew_user ;;
            6)  domain_menu ;;
            7)  service_menu ;;
            8)  telegram_menu ;;
            9)  theme_menu ;;
            10) update_zivpn ;;
            11) show_vps_full ;;
            12) reinstall_binary ;;
            13) uninstall_zivpn ;;
            0)  echo -e "\n  ${TC}Sampai jumpa! 👋${NC}\n"; exit 0 ;;
            *)  echo -e "  ${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
        esac
    done
}

# ─── VPS FULL INFO ───────────────────────────────────────────
show_vps_full() {
    show_logo
    echo -e "  ${TC2}${BOLD}📊 INFO VPS LENGKAP${NC}"
    thin_line
    echo
    echo -e "  ${WHITE}Hostname     ${NC}: ${TC}$(hostname)${NC}"
    echo -e "  ${WHITE}IP Public    ${NC}: ${TC}$(curl -s --max-time 3 ifconfig.me)${NC}"
    echo -e "  ${WHITE}IP Private   ${NC}: ${TC}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "  ${WHITE}OS           ${NC}: ${TC}$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)${NC}"
    echo -e "  ${WHITE}Kernel       ${NC}: ${TC}$(uname -r)${NC}"
    echo -e "  ${WHITE}CPU          ${NC}: ${TC}$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)${NC}"
    echo -e "  ${WHITE}CPU Cores    ${NC}: ${TC}$(nproc) Core${NC}"
    echo -e "  ${WHITE}CPU Usage    ${NC}: ${TC}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%${NC}"
    echo -e "  ${WHITE}RAM Total    ${NC}: ${TC}$(free -m | awk '/Mem:/{print $2}') MB${NC}"
    echo -e "  ${WHITE}RAM Used     ${NC}: ${TC}$(free -m | awk '/Mem:/{print $3}') MB${NC}"
    echo -e "  ${WHITE}RAM Free     ${NC}: ${TC}$(free -m | awk '/Mem:/{print $4}') MB${NC}"
    echo -e "  ${WHITE}Disk Total   ${NC}: ${TC}$(df -h / | awk 'NR==2{print $2}')${NC}"
    echo -e "  ${WHITE}Disk Used    ${NC}: ${TC}$(df -h / | awk 'NR==2{print $3}')${NC}"
    echo -e "  ${WHITE}Disk Free    ${NC}: ${TC}$(df -h / | awk 'NR==2{print $4}')${NC}"
    echo -e "  ${WHITE}Load Avg     ${NC}: ${TC}$(cat /proc/loadavg | awk '{print $1,$2,$3}')${NC}"
    echo -e "  ${WHITE}Uptime       ${NC}: ${TC}$(uptime -p)${NC}"
    echo -e "  ${WHITE}ZivPN Status ${NC}: $(service_status)"
    echo
    divider
    echo
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── ENTRY POINT ─────────────────────────────────────────────
load_theme
main_menu
