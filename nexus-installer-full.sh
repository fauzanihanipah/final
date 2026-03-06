!/bin/bash
# Zivpn UDP Module installer - Fixed 
# Creator Deki_niswara

# Fix for sudo: unable to resolve host
HOSTNAME=$(hostname)
if ! grep -q "127.0.0.1 $HOSTNAME" /etc/hosts; then
    echo "Adding $HOSTNAME to /etc/hosts"
    sudo bash -c "echo '127.0.0.1 $HOSTNAME' >> /etc/hosts"
fi

echo -e "Updating server"
sudo apt-get update && sudo apt-get upgrade -y
if ! command -v ufw &> /dev/null
then
    echo "ufw could not be found, installing it now..."
    sudo apt-get install ufw -y
fi
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, installing it now..."
    sudo apt-get install jq -y
fi
if ! command -v curl &> /dev/null
then
    echo "curl could not be found, installing it now..."
    sudo apt-get install curl -y
fi

# Meminta domain dari pengguna
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m'
echo -e "${YELLOW}┌──────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│   Silakan masukkan nama domain Anda      │${NC}"
echo -e "${YELLOW}└──────────────────────────────────────────┘${NC}"
echo -n -e "${WHITE}└──> ${NC}"
read user_domain
if [ -z "$user_domain" ]; then
    echo -e "${RED}Nama domain tidak boleh kosong. Menggunakan hostname sebagai fallback.${NC}"
    user_domain=$(hostname)
fi
echo "Domain Anda akan disimpan sebagai: $user_domain"
sleep 2

if ! command -v figlet &> /dev/null; then
    echo "figlet not found, installing..."
    sudo apt-get install -y figlet
fi

if ! command -v lolcat &> /dev/null; then
    echo "lolcat not found, installing..."
    sudo apt-get install -y ruby-full
    sudo gem install lolcat
fi


# Stop service kalau ada
sudo systemctl stop zivpn.service > /dev/null 2>&1

echo -e "Downloading UDP Service"
sudo wget https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn-bin
sudo chmod +x /usr/local/bin/zivpn-bin
sudo mkdir -p /etc/zivpn
sudo wget https://raw.githubusercontent.com/fauzanihanipah/ziv-udp/main/config.json -O /etc/zivpn/config.json

echo "Generating cert files:"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sudo sysctl -w net.core.rmem_max=16777216 > /dev/null
sudo sysctl -w net.core.wmem_max=16777216 > /dev/null

sudo bash -c 'cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn-bin server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF'

# Buat file database pengguna awal, file tema, dan file domain
sudo bash -c 'echo "[]" > /etc/zivpn/users.db.json'
sudo bash -c 'echo "rainbow" > /etc/zivpn/theme.conf'
sudo bash -c "echo \"$user_domain\" > /etc/zivpn/domain.conf"

# Bersihin iptables rules yang lama
INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
while sudo iptables -t nat -D PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null; do :; done
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
sudo iptables -A FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -o $INTERFACE -j MASQUERADE
sudo apt install iptables-persistent -y -qq
sudo netfilter-persistent save > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable zivpn.service
sudo systemctl start zivpn.service
sudo ufw allow 6000:19999/udp > /dev/null
sudo ufw allow 5667/udp > /dev/null

# ============================================================
#   LANJUTAN: Setup Menu NEXUS ZIVPN
# ============================================================

# Salin script ini ke /usr/local/bin/menu supaya bisa dipanggil kapan saja
SCRIPT_PATH="$(readlink -f "$0")"
sudo cp "$SCRIPT_PATH" /usr/local/bin/menu
sudo chmod +x /usr/local/bin/menu

# Tambahkan alias ke .bashrc root
if ! grep -q 'alias menu=' /root/.bashrc 2>/dev/null; then
    echo 'alias menu="/usr/local/bin/menu --menu"' >> /root/.bashrc
fi

echo -e "\n\033[1;32m✓ Instalasi selesai! Ketik 'menu' untuk membuka panel.\033[0m\n"
sleep 2

# ============================================================
#   MENU PANEL — hanya berjalan kalau dipanggil ulang
# ============================================================
[[ "$1" != "--menu" && "$(basename "$0")" != "menu" ]] && exit 0

# ─── PATH ────────────────────────────────────────────────────
CONFIG_DIR="/etc/zivpn"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
USER_DB="$CONFIG_DIR/users.db"
USER_DB_JSON="$CONFIG_DIR/users.db.json"
THEME_FILE="$CONFIG_DIR/theme.conf"
DOMAIN_FILE="$CONFIG_DIR/domain.conf"
TG_FILE="$CONFIG_DIR/telegram.conf"
LOG_FILE="/var/log/zivpn.log"
BINARY_URL="https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64"
CONFIG_URL="https://raw.githubusercontent.com/fauzanihanipah/ziv-udp/main/config.json"

# ─── WARNA ───────────────────────────────────────────────────
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
RAINBOW_C=('\033[0;31m' '\033[0;33m' '\033[1;33m' '\033[0;32m' '\033[0;36m' '\033[0;34m' '\033[0;35m')

# ─── LOAD TEMA ───────────────────────────────────────────────
load_theme() {
    CURRENT_THEME="rainbow"
    [[ -f "$THEME_FILE" ]] && CURRENT_THEME=$(cat "$THEME_FILE" 2>/dev/null)
    case "$CURRENT_THEME" in
        green)  TC='\033[0;32m'; TC2='\033[1;32m' ;;
        blue)   TC='\033[0;34m'; TC2='\033[1;34m' ;;
        red)    TC='\033[0;31m'; TC2='\033[1;31m' ;;
        yellow) TC='\033[1;33m'; TC2='\033[0;33m' ;;
        cyan)   TC='\033[0;36m'; TC2='\033[1;36m' ;;
        *)      TC='\033[0;36m'; TC2='\033[0;35m' ;;  # rainbow default ke cyan/magenta
    esac
}

# ─── RAINBOW TEXT ────────────────────────────────────────────
rainbow_echo() {
    local text="$1" i=0
    for (( c=0; c<${#text}; c++ )); do
        echo -ne "${RAINBOW_C[$((i % 7))]}${text:$c:1}"
        ((i++))
    done
    echo -ne "${NC}"
}

# ─── GARIS ───────────────────────────────────────────────────
line_thick() {
    if [[ "$CURRENT_THEME" == "rainbow" ]]; then
        rainbow_echo "  ══════════════════════════════════════════════════════"
        echo
    else
        echo -e "  ${TC}══════════════════════════════════════════════════════${NC}"
    fi
}

line_thin() {
    echo -e "  ${DIM}${TC}──────────────────────────────────────────────────────${NC}"
}

# ─── INFO VPS ────────────────────────────────────────────────
gather_vps_info() {
    VPS_HOST=$(hostname 2>/dev/null)
    VPS_OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2)
    VPS_KERNEL=$(uname -r 2>/dev/null)
    VPS_CPU=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs)
    VPS_CORES=$(nproc 2>/dev/null)
    VPS_RAM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/{print $2}')
    VPS_RAM_USED=$(free -m 2>/dev/null | awk '/Mem:/{print $3}')
    VPS_DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
    VPS_DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
    VPS_UPTIME=$(uptime -p 2>/dev/null)
    VPS_IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    VPS_LOAD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1,$2,$3}')
    VPS_CPU_USE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | xargs)
}

# ─── STATUS SERVICE ──────────────────────────────────────────
svc_status() {
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "${G}${BOLD}● AKTIF${NC}"
    else
        echo -e "${R}${BOLD}● MATI${NC}"
    fi
}

# ─── LOGO + INFO VPS ─────────────────────────────────────────
show_header() {
    clear
    load_theme
    gather_vps_info
    echo
    # Logo NEXUS miring ke kanan (italic-style ASCII slant)
    if [[ "$CURRENT_THEME" == "rainbow" ]]; then
        rainbow_echo "    /|  | ____ _  __ __ __ _____"  ; echo
        rainbow_echo "   / |  ||  __\\ \\/ // // // ___/"  ; echo
        rainbow_echo "  /  |  || |__ >  < || || |\\___ \\" ; echo
        rainbow_echo " / /|   ||  __// /\\ \\| || | ___) |"; echo
        rainbow_echo "/_/ |___||____/_/  \\_\\___/ /____/ "; echo
        echo
        rainbow_echo "       ░▒▓  N E X U S  Z I V P N  ▓▒░"
        echo
    else
        echo -e "${TC2}${BOLD}    /|  | ____ _  __ __ __ _____${NC}"
        echo -e "${TC2}${BOLD}   / |  ||  __\\ \\/ // // // ___/${NC}"
        echo -e "${TC}${BOLD}  /  |  || |__ >  < || || |\\___ \\${NC}"
        echo -e "${TC}${BOLD} / /|   ||  __// /\\ \\| || | ___) |${NC}"
        echo -e "${TC2}${BOLD}/_/ |___||____/_/  \\_\\___/ /____/ ${NC}"
        echo
        echo -e "${W}${BOLD}       ░▒▓  N E X U S  Z I V P N  ▓▒░${NC}"
        echo
    fi
    line_thick
    # Info VPS
    echo -e "  ${W}${BOLD}📡 INFO VPS${NC}"
    line_thin
    echo -e "  ${W}🖥  Hostname  ${NC}: ${TC}${VPS_HOST}${NC}"
    echo -e "  ${W}🌐 IP Public ${NC}: ${TC}${VPS_IP}${NC}"
    echo -e "  ${W}💿 OS        ${NC}: ${TC}${VPS_OS}${NC}"
    echo -e "  ${W}🐧 Kernel    ${NC}: ${TC}${VPS_KERNEL}${NC}"
    echo -e "  ${W}⚙️  CPU       ${NC}: ${TC}${VPS_CPU} (${VPS_CORES} Core)${NC}"
    echo -e "  ${W}📊 CPU Usage ${NC}: ${TC}${VPS_CPU_USE}%  |  Load: ${VPS_LOAD}${NC}"
    echo -e "  ${W}🧠 RAM       ${NC}: ${TC}${VPS_RAM_USED} MB / ${VPS_RAM_TOTAL} MB${NC}"
    echo -e "  ${W}💾 Disk      ${NC}: ${TC}${VPS_DISK_USED} / ${VPS_DISK_TOTAL}${NC}"
    echo -e "  ${W}⏱  Uptime    ${NC}: ${TC}${VPS_UPTIME}${NC}"
    echo -e "  ${W}⚡ Service   ${NC}: $(svc_status)"
    line_thick
    echo
}

# ─── TELEGRAM NOTIFY ─────────────────────────────────────────
tg_notify() {
    local MSG="$1"
    [[ ! -f "$TG_FILE" ]] && return
    local TK=$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
    local CID=$(grep '^CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
    [[ -z "$TK" || -z "$CID" ]] && return
    curl -s --max-time 5 \
        "https://api.telegram.org/bot${TK}/sendMessage" \
        -d "chat_id=${CID}&text=${MSG}&parse_mode=Markdown" > /dev/null 2>&1 &
}

# ─── SIMPAN USER KE JSON ─────────────────────────────────────
save_user_json() {
    # Rebuild JSON dari flat db
    local json="["
    local first=1
    while IFS=':' read -r USR EXP PW; do
        [[ -z "$USR" ]] && continue
        [[ $first -eq 0 ]] && json+=","
        json+="{\"user\":\"$USR\",\"exp\":\"$EXP\",\"pass\":\"$PW\"}"
        first=0
    done < "$USER_DB" 2>/dev/null
    json+="]"
    echo "$json" > "$USER_DB_JSON"
}

# ─── TAMBAH AKUN ─────────────────────────────────────────────
add_user() {
    show_header
    echo -e "  ${TC2}${BOLD}➕ TAMBAH AKUN UDP ZIVPN${NC}"
    line_thin; echo

    read -rp "  Username       : " USR
    [[ -z "$USR" ]] && echo -e "  ${R}✗ Username kosong!${NC}" && sleep 1 && return
    grep -q "^${USR}:" "$USER_DB" 2>/dev/null && echo -e "  ${Y}⚠ Username sudah ada!${NC}" && sleep 1 && return

    read -rp "  Password       : " PW
    [[ -z "$PW" ]] && echo -e "  ${R}✗ Password kosong!${NC}" && sleep 1 && return

    read -rp "  Masa aktif (hari) [30] : " DAYS
    DAYS=${DAYS:-30}
    EXP=$(date -d "+${DAYS} days" +%Y%m%d 2>/dev/null || date +%Y%m%d)
    EXP_FMT=$(date -d "$EXP" '+%d-%m-%Y' 2>/dev/null || echo "$EXP")

    echo "${USR}:${EXP}:${PW}" >> "$USER_DB"
    save_user_json

    DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$VPS_IP")
    PORT="5667"

    echo
    line_thick
    echo -e "  ${G}${BOLD}✓ AKUN BERHASIL DIBUAT${NC}"
    line_thin
    echo -e "  ${W}👤 Username  ${NC}: ${TC}$USR${NC}"
    echo -e "  ${W}🔑 Password  ${NC}: ${TC}$PW${NC}"
    echo -e "  ${W}📅 Expired   ${NC}: ${TC}$EXP_FMT${NC}"
    echo -e "  ${W}🌐 Host      ${NC}: ${TC}$DOM${NC}"
    echo -e "  ${W}🔌 Port      ${NC}: ${TC}$PORT${NC}"
    line_thick
    echo
    tg_notify "➕ *AKUN BARU DIBUAT*%0AUsername: \`$USR\`%0APassword: \`$PW\`%0AExpired: $EXP_FMT%0AHost: $DOM:$PORT"
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── LIST AKUN ───────────────────────────────────────────────
list_users() {
    show_header
    echo -e "  ${TC2}${BOLD}📋 DAFTAR AKUN UDP ZIVPN${NC}"
    line_thin; echo
    printf "  ${TC}%-3s %-18s %-12s %-10s${NC}\n" "NO" "USERNAME" "EXPIRED" "STATUS"
    line_thin
    TODAY=$(date +%Y%m%d)
    COUNT=0
    while IFS=':' read -r USR EXP PW; do
        [[ -z "$USR" ]] && continue
        ((COUNT++))
        EXP_FMT=$(date -d "$EXP" '+%d-%m-%Y' 2>/dev/null || echo "$EXP")
        if [[ "$TODAY" -le "$EXP" ]]; then
            DAYS_LEFT=$(( ( $(date -d "$EXP" +%s 2>/dev/null || echo 0) - $(date +%s) ) / 86400 ))
            ST="${G}Aktif (${DAYS_LEFT}h)${NC}"
        else
            ST="${R}Expired${NC}"
        fi
        printf "  %-3s %-18s %-12s " "$COUNT" "$USR" "$EXP_FMT"
        echo -e "$ST"
    done < "$USER_DB" 2>/dev/null
    echo
    line_thin
    echo -e "  Total: ${TC2}$COUNT akun${NC}"
    line_thick; echo
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── HAPUS AKUN ──────────────────────────────────────────────
delete_user() {
    show_header
    echo -e "  ${TC2}${BOLD}🗑  HAPUS AKUN${NC}"
    line_thin; echo
    # tampilkan list singkat
    while IFS=':' read -r USR EXP PW; do
        [[ -z "$USR" ]] && continue
        echo -e "   ${TC}•${NC} $USR"
    done < "$USER_DB" 2>/dev/null
    echo
    read -rp "  Username yang dihapus : " USR
    [[ -z "$USR" ]] && return
    if grep -q "^${USR}:" "$USER_DB" 2>/dev/null; then
        sed -i "/^${USR}:/d" "$USER_DB"
        save_user_json
        echo -e "  ${G}✓ Akun ${USR} berhasil dihapus!${NC}"
        tg_notify "🗑 *AKUN DIHAPUS*%0AUsername: \`$USR\`"
    else
        echo -e "  ${R}✗ Akun tidak ditemukan!${NC}"
    fi
    sleep 1
}

# ─── PERPANJANG AKUN ─────────────────────────────────────────
renew_user() {
    show_header
    echo -e "  ${TC2}${BOLD}🔄 PERPANJANG AKUN${NC}"
    line_thin; echo
    while IFS=':' read -r USR EXP PW; do
        [[ -z "$USR" ]] && continue
        EXP_FMT=$(date -d "$EXP" '+%d-%m-%Y' 2>/dev/null || echo "$EXP")
        echo -e "   ${TC}•${NC} $USR  ${DIM}(exp: $EXP_FMT)${NC}"
    done < "$USER_DB" 2>/dev/null
    echo
    read -rp "  Username : " USR
    [[ -z "$USR" ]] && return
    if ! grep -q "^${USR}:" "$USER_DB" 2>/dev/null; then
        echo -e "  ${R}✗ Akun tidak ditemukan!${NC}"; sleep 1; return
    fi
    read -rp "  Tambah hari [30] : " DAYS
    DAYS=${DAYS:-30}
    OLD_EXP=$(grep "^${USR}:" "$USER_DB" | cut -d':' -f2)
    PW=$(grep "^${USR}:" "$USER_DB" | cut -d':' -f3)
    NEW_EXP=$(date -d "${OLD_EXP}+${DAYS} days" +%Y%m%d 2>/dev/null || echo "$OLD_EXP")
    NEW_FMT=$(date -d "$NEW_EXP" '+%d-%m-%Y' 2>/dev/null || echo "$NEW_EXP")
    sed -i "s/^${USR}:.*/${USR}:${NEW_EXP}:${PW}/" "$USER_DB"
    save_user_json
    echo -e "  ${G}✓ Akun diperpanjang s/d ${NEW_FMT}${NC}"
    tg_notify "🔄 *AKUN DIPERPANJANG*%0AUsername: \`$USR\`%0AExpired baru: $NEW_FMT"
    sleep 1
}

# ─── MENU DOMAIN ─────────────────────────────────────────────
domain_menu() {
    while true; do
        show_header
        echo -e "  ${TC2}${BOLD}🌐 PENGATURAN DOMAIN${NC}"
        line_thin; echo
        DOM_NOW=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Belum diatur")
        echo -e "  Domain aktif : ${TC2}${DOM_NOW}${NC}"
        echo
        echo -e "  ${TC}[1]${NC}  ✏️   Set / Ganti Domain"
        echo -e "  ${TC}[2]${NC}  🗑   Hapus Domain (pakai IP)"
        echo -e "  ${TC}[3]${NC}  🔍  Cek DNS Domain"
        echo -e "  ${TC}[4]${NC}  📋  Tampilkan Info Koneksi"
        echo -e "  ${TC}[0]${NC}  ↩️   Kembali"
        echo
        read -rp "  Pilih [0-4] : " OPT
        case $OPT in
            1)
                echo; read -rp "  Domain baru : " ND
                [[ -z "$ND" ]] && continue
                echo "$ND" > "$DOMAIN_FILE"
                echo -e "  ${G}✓ Domain diset: $ND${NC}"; sleep 1 ;;
            2)
                rm -f "$DOMAIN_FILE"
                echo -e "  ${Y}✓ Domain dihapus, menggunakan IP${NC}"; sleep 1 ;;
            3)
                echo; read -rp "  Domain yang dicek : " CD
                echo -e "\n  ${TC}Hasil DNS:${NC}"
                nslookup "$CD" 2>/dev/null || host "$CD" 2>/dev/null || echo "  nslookup tidak tersedia"
                echo; read -rp "  ENTER..." _ ;;
            4)
                DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$VPS_IP")
                echo
                line_thin
                echo -e "  ${W}🌐 Host   ${NC}: ${TC}$DOM${NC}"
                echo -e "  ${W}🔌 Port   ${NC}: ${TC}5667${NC}  (UDP 6000-19999)"
                echo -e "  ${W}🔒 Obfs   ${NC}: ${TC}zivpn${NC}"
                line_thin
                echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
    done
}

# ─── MENU SERVICE ────────────────────────────────────────────
service_menu() {
    while true; do
        show_header
        echo -e "  ${TC2}${BOLD}⚙️  MANAJEMEN SERVICE${NC}"
        line_thin; echo
        echo -e "  Status : $(svc_status)"
        echo
        echo -e "  ${TC}[1]${NC}  ▶️   Start Service"
        echo -e "  ${TC}[2]${NC}  ⏹️   Stop Service"
        echo -e "  ${TC}[3]${NC}  🔄  Restart Service"
        echo -e "  ${TC}[4]${NC}  📜  Lihat Log (30 baris)"
        echo -e "  ${TC}[5]${NC}  📋  Status Detail"
        echo -e "  ${TC}[6]${NC}  🔧  Reinstall Binary"
        echo -e "  ${TC}[0]${NC}  ↩️   Kembali"
        echo
        read -rp "  Pilih [0-6] : " OPT
        case $OPT in
            1) sudo systemctl start zivpn && echo -e "  ${G}✓ Service distart${NC}" ;;
            2) sudo systemctl stop zivpn && echo -e "  ${Y}✓ Service distop${NC}" ;;
            3) sudo systemctl restart zivpn && echo -e "  ${G}✓ Service direstart${NC}" ;;
            4) echo; sudo journalctl -u zivpn -n 30 --no-pager 2>/dev/null || tail -30 "$LOG_FILE" 2>/dev/null; echo; read -rp "  ENTER..." _ ;;
            5) echo; sudo systemctl status zivpn; echo; read -rp "  ENTER..." _ ;;
            6) reinstall_binary ;;
            0) break ;;
        esac
        [[ "$OPT" =~ ^[1-3]$ ]] && sleep 1
    done
}

# ─── REINSTALL BINARY ────────────────────────────────────────
reinstall_binary() {
    show_header
    echo -e "  ${TC2}${BOLD}🔧 REINSTALL BINARY ZIVPN${NC}"
    line_thin; echo
    echo -e "  ${Y}Binary akan diunduh ulang dari GitHub.${NC}"
    echo -e "  ${DIM}Akun & konfigurasi TIDAK terhapus.${NC}"
    echo
    echo -e "  ${TC}[1]${NC}  Reinstall binary saja"
    echo -e "  ${TC}[2]${NC}  Reinstall binary + reset config.json"
    echo -e "  ${TC}[0]${NC}  Batal"
    echo
    read -rp "  Pilih [0-2] : " OPT
    [[ "$OPT" == "0" ]] && return

    echo
    echo -e "  ${C}[1/3]${NC} Menghentikan service..."
    sudo systemctl stop zivpn 2>/dev/null; sleep 1

    echo -e "  ${C}[2/3]${NC} Mengunduh ulang binary..."
    if sudo wget -q --show-progress -O /tmp/zivpn-reinstall "$BINARY_URL" 2>&1; then
        [[ -f /usr/local/bin/zivpn-bin ]] && sudo cp /usr/local/bin/zivpn-bin /usr/local/bin/zivpn-bin.bak
        sudo mv /tmp/zivpn-reinstall /usr/local/bin/zivpn-bin
        sudo chmod +x /usr/local/bin/zivpn-bin
        echo -e "  ${G}  ✓ Binary berhasil diunduh ulang${NC}"
        echo -e "  ${DIM}    Backup: /usr/local/bin/zivpn-bin.bak${NC}"
    else
        echo -e "  ${R}  ✗ Gagal! Memulihkan backup...${NC}"
        [[ -f /usr/local/bin/zivpn-bin.bak ]] && sudo mv /usr/local/bin/zivpn-bin.bak /usr/local/bin/zivpn-bin
        sudo systemctl start zivpn 2>/dev/null; sleep 2; return
    fi

    if [[ "$OPT" == "2" ]]; then
        echo -e "       Mengunduh ulang config.json..."
        [[ -f "$CONFIG_DIR/config.json" ]] && sudo cp "$CONFIG_DIR/config.json" "$CONFIG_DIR/config.json.bak"
        sudo wget -q -O "$CONFIG_DIR/config.json" "$CONFIG_URL" 2>/dev/null \
            && echo -e "  ${G}  ✓ Config diunduh ulang${NC}" \
            || echo -e "  ${Y}  ⚠ Gagal, menggunakan config lama${NC}"
    fi

    echo -e "  ${C}[3/3]${NC} Menjalankan ulang service..."
    sudo systemctl start zivpn 2>/dev/null; sleep 1

    echo; line_thick
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "  ${G}${BOLD}✓ Reinstall selesai! Service aktif.${NC}"
    else
        echo -e "  ${Y}⚠ Reinstall selesai, tapi service tidak aktif.${NC}"
    fi
    line_thick; echo
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── MENU TELEGRAM ───────────────────────────────────────────
telegram_menu() {
    while true; do
        show_header
        echo -e "  ${TC2}${BOLD}🤖 TELEGRAM BOT${NC}"
        line_thin; echo
        TK=$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        CID=$(grep '^CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        echo -e "  Bot Token : ${TC}${TK:-Belum diatur}${NC}"
        echo -e "  Chat ID   : ${TC}${CID:-Belum diatur}${NC}"
        echo
        echo -e "  ${TC}[1]${NC}  🔑  Set Bot Token"
        echo -e "  ${TC}[2]${NC}  💬  Set Chat ID"
        echo -e "  ${TC}[3]${NC}  📡  Test Koneksi Bot"
        echo -e "  ${TC}[4]${NC}  📊  Kirim Laporan VPS"
        echo -e "  ${TC}[5]${NC}  📋  Kirim Daftar Akun"
        echo -e "  ${TC}[6]${NC}  🗑   Hapus Konfigurasi"
        echo -e "  ${TC}[0]${NC}  ↩️   Kembali"
        echo
        read -rp "  Pilih [0-6] : " OPT
        case $OPT in
            1)
                echo; read -rp "  Bot Token : " TKN
                [[ -z "$TKN" ]] && continue
                sudo mkdir -p "$CONFIG_DIR"
                grep -q '^TOKEN=' "$TG_FILE" 2>/dev/null \
                    && sudo sed -i "s|^TOKEN=.*|TOKEN=$TKN|" "$TG_FILE" \
                    || echo "TOKEN=$TKN" | sudo tee -a "$TG_FILE" > /dev/null
                echo -e "  ${G}✓ Token disimpan${NC}"; sleep 1 ;;
            2)
                echo; read -rp "  Chat ID : " CIDD
                [[ -z "$CIDD" ]] && continue
                grep -q '^CHATID=' "$TG_FILE" 2>/dev/null \
                    && sudo sed -i "s|^CHATID=.*|CHATID=$CIDD|" "$TG_FILE" \
                    || echo "CHATID=$CIDD" | sudo tee -a "$TG_FILE" > /dev/null
                echo -e "  ${G}✓ Chat ID disimpan${NC}"; sleep 1 ;;
            3)
                tg_notify "✅ *Test Berhasil!*%0ANEXUS ZIVPN terhubung ke bot Telegram.%0AHost: $VPS_HOST | IP: $VPS_IP"
                echo -e "  ${G}✓ Pesan test dikirim, cek Telegram kamu!${NC}"; sleep 2 ;;
            4)
                MSG="📊 *LAPORAN VPS - NEXUS ZIVPN*%0AHost: $VPS_HOST%0AIP: $VPS_IP%0AOS: $VPS_OS%0ARAM: ${VPS_RAM_USED}/${VPS_RAM_TOTAL} MB%0ADisk: $VPS_DISK_USED/$VPS_DISK_TOTAL%0AUptime: $VPS_UPTIME%0AService: $(systemctl is-active zivpn 2>/dev/null)"
                tg_notify "$MSG"
                echo -e "  ${G}✓ Laporan dikirim${NC}"; sleep 2 ;;
            5)
                COUNT=0
                MSG="📋 *DAFTAR AKUN ZIVPN*%0A"
                while IFS=':' read -r USR EXP PW; do
                    [[ -z "$USR" ]] && continue
                    EXP_F=$(date -d "$EXP" '+%d-%m-%Y' 2>/dev/null || echo "$EXP")
                    MSG+="• \`$USR\` — exp: $EXP_F%0A"
                    ((COUNT++))
                done < "$USER_DB" 2>/dev/null
                MSG+="Total: $COUNT akun"
                tg_notify "$MSG"
                echo -e "  ${G}✓ Daftar akun dikirim ke Telegram${NC}"; sleep 2 ;;
            6)
                sudo rm -f "$TG_FILE"
                echo -e "  ${Y}✓ Konfigurasi Telegram dihapus${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ─── MENU TEMA ───────────────────────────────────────────────
theme_menu() {
    while true; do
        show_header
        echo -e "  ${TC2}${BOLD}🎨 PILIH TEMA${NC}"
        line_thin; echo
        echo -e "  Tema aktif : ${TC2}${CURRENT_THEME}${NC}"
        echo
        echo -e "  ${C}[1]${NC}  🔵 Cyan (Default)"
        echo -e "  ${G}[2]${NC}  🟢 Green"
        echo -e "  ${B}[3]${NC}  🔷 Blue"
        echo -e "  ${R}[4]${NC}  🔴 Red"
        echo -e "  ${Y}[5]${NC}  🟡 Yellow"
        echo -ne "  "; rainbow_echo "[6]  🌈 Rainbow Pelangi ✨ (Aktif default)"; echo
        echo -e "  ${DIM}[0]  ↩️  Kembali${NC}"
        echo
        read -rp "  Pilih tema [0-6] : " OPT
        case $OPT in
            1) echo "cyan"    | sudo tee "$THEME_FILE" > /dev/null ;;
            2) echo "green"   | sudo tee "$THEME_FILE" > /dev/null ;;
            3) echo "blue"    | sudo tee "$THEME_FILE" > /dev/null ;;
            4) echo "red"     | sudo tee "$THEME_FILE" > /dev/null ;;
            5) echo "yellow"  | sudo tee "$THEME_FILE" > /dev/null ;;
            6) echo "rainbow" | sudo tee "$THEME_FILE" > /dev/null ;;
            0) break ;;
        esac
        load_theme
        [[ "$OPT" =~ ^[1-6]$ ]] && echo -e "  ${G}✓ Tema berhasil diganti!${NC}" && sleep 1
    done
}

# ─── INFO VPS LENGKAP ────────────────────────────────────────
vps_full_info() {
    show_header
    echo -e "  ${TC2}${BOLD}📊 INFO VPS LENGKAP${NC}"
    line_thin; echo
    echo -e "  ${W}Hostname    ${NC}: ${TC}$(hostname)${NC}"
    echo -e "  ${W}IP Public   ${NC}: ${TC}$(curl -s --max-time 3 ifconfig.me 2>/dev/null)${NC}"
    echo -e "  ${W}IP Private  ${NC}: ${TC}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "  ${W}OS          ${NC}: ${TC}$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)${NC}"
    echo -e "  ${W}Kernel      ${NC}: ${TC}$(uname -r)${NC}"
    echo -e "  ${W}Arch        ${NC}: ${TC}$(uname -m)${NC}"
    echo -e "  ${W}CPU         ${NC}: ${TC}$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)${NC}"
    echo -e "  ${W}CPU Cores   ${NC}: ${TC}$(nproc) Core${NC}"
    echo -e "  ${W}CPU Usage   ${NC}: ${TC}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%${NC}"
    echo -e "  ${W}RAM Total   ${NC}: ${TC}$(free -m | awk '/Mem:/{print $2}') MB${NC}"
    echo -e "  ${W}RAM Used    ${NC}: ${TC}$(free -m | awk '/Mem:/{print $3}') MB${NC}"
    echo -e "  ${W}RAM Free    ${NC}: ${TC}$(free -m | awk '/Mem:/{print $4}') MB${NC}"
    echo -e "  ${W}SWAP Total  ${NC}: ${TC}$(free -m | awk '/Swap:/{print $2}') MB${NC}"
    echo -e "  ${W}SWAP Used   ${NC}: ${TC}$(free -m | awk '/Swap:/{print $3}') MB${NC}"
    echo -e "  ${W}Disk Total  ${NC}: ${TC}$(df -h / | awk 'NR==2{print $2}')${NC}"
    echo -e "  ${W}Disk Used   ${NC}: ${TC}$(df -h / | awk 'NR==2{print $3}')${NC}"
    echo -e "  ${W}Disk Free   ${NC}: ${TC}$(df -h / | awk 'NR==2{print $4}')${NC}"
    echo -e "  ${W}Load Avg    ${NC}: ${TC}$(cat /proc/loadavg | awk '{print $1,$2,$3}')${NC}"
    echo -e "  ${W}Uptime      ${NC}: ${TC}$(uptime -p)${NC}"
    echo -e "  ${W}Service     ${NC}: $(svc_status)"
    echo -e "  ${W}Domain      ${NC}: ${TC}$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Belum diatur")${NC}"
    echo
    line_thick; echo
    read -rp "  Tekan ENTER untuk kembali..." _
}

# ─── MENU UTAMA ──────────────────────────────────────────────
main_menu() {
    while true; do
        show_header
        echo -e "  ${TC2}${BOLD}📌 MENU UTAMA${NC}"
        line_thin
        echo
        echo -e "  ${TC}[1]${NC}  ➕  Tambah Akun"
        echo -e "  ${TC}[2]${NC}  📋  List Akun"
        echo -e "  ${TC}[3]${NC}  🗑   Hapus Akun"
        echo -e "  ${TC}[4]${NC}  🔄  Perpanjang Akun"
        line_thin
        echo -e "  ${TC}[5]${NC}  🌐  Pengaturan Domain"
        echo -e "  ${TC}[6]${NC}  ⚙️   Manajemen Service"
        echo -e "  ${TC}[7]${NC}  🤖  Telegram Bot"
        echo -e "  ${TC}[8]${NC}  🎨  Pilih Tema"
        line_thin
        echo -e "  ${TC}[9]${NC}  📊  Info VPS Lengkap"
        echo -e "  ${TC}[10]${NC} 🔧  Reinstall Binary"
        line_thin
        echo -e "  ${DIM}[0]  🚪  Keluar${NC}"
        echo
        read -rp "  Pilih menu [0-10] : " CH
        case $CH in
            1)  add_user ;;
            2)  list_users ;;
            3)  delete_user ;;
            4)  renew_user ;;
            5)  domain_menu ;;
            6)  service_menu ;;
            7)  telegram_menu ;;
            8)  theme_menu ;;
            9)  vps_full_info ;;
            10) reinstall_binary ;;
            0)  echo -e "\n  ${TC}Sampai jumpa! 👋${NC}\n"; exit 0 ;;
            *)  echo -e "  ${R}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# ─── JALANKAN ────────────────────────────────────────────────
load_theme
main_menu
