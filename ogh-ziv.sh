#!/bin/bash
# ================================================================
#   OGH-ZIV PREMIUM — UDP VPN MANAGER
#   Binary : github.com/fauzanihanipah/ziv-udp
# ================================================================

# ── WARNA ────────────────────────────────────────────────────────
R='\033[0;31m'; LR='\033[1;31m'
G='\033[0;32m'; LG='\033[1;32m'
Y='\033[1;33m'
C='\033[0;36m'; LC='\033[1;36m'
M='\033[0;35m'; LM='\033[1;35m'
W='\033[1;37m'
D='\033[2m'; IT='\033[3m'
BLD='\033[1m'; NC='\033[0m'
VIO='\033[38;5;135m'
VIL='\033[38;5;141m'
WHT='\033[38;5;231m'

# ── PATH ─────────────────────────────────────────────────────────
DIR="/etc/zivpn"
BIN="/usr/local/bin/zivpn"
CFG="$DIR/config.json"
SVC="/etc/systemd/system/zivpn.service"
BINARY_URL="https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64"
UDB="$DIR/users.db"
LOG="$DIR/zivpn.log"
DOMF="$DIR/domain.conf"
BOTF="$DIR/bot.conf"
STRF="$DIR/store.conf"

# ── UTILS ────────────────────────────────────────────────────────
check_root() { [[ $EUID -ne 0 ]] && { echo -e "\n${LR}✘ Jalankan sebagai root!${NC}\n"; exit 1; }; }
ok()    { echo -e "  ${LG}✔${NC}  $*"; }
inf()   { echo -e "  ${LC}➜${NC}  $*"; }
warn()  { echo -e "  ${Y}⚠${NC}  $*"; }
err()   { echo -e "  ${LR}✘${NC}  $*"; }
pause() { echo ""; echo -ne "  ${D}╰─ [ Enter ] kembali ke menu...${NC}"; read -r; }

get_ip()     { curl -s4 --max-time 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'; }
get_port()   { grep -o '"listen":":[0-9]*"\|"listen": *":[0-9]*"' "$CFG" 2>/dev/null | grep -o '[0-9]*' || echo "5667"; }
get_domain() { cat "$DOMF" 2>/dev/null || get_ip; }
is_up()      { systemctl is-active --quiet zivpn 2>/dev/null; }
total_user() { [[ -f "$UDB" ]] && grep -c '' "$UDB" 2>/dev/null || echo 0; }
exp_count()  {
    local t; t=$(date +%Y-%m-%d)
    [[ -f "$UDB" ]] && awk -F'|' -v d="$t" '$3<d{c++}END{print c+0}' "$UDB" || echo 0
}
rand_pass()  { tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12; }

# ════════════════════════════════════════════════════════════════
#  LOGO OGH-ZIV — MIRING KANAN, VIOLET, BERGARIS PUTIH
# ════════════════════════════════════════════════════════════════
draw_logo() {
    echo ""
    echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${VIO}║${NC}  ${WHT}${D}////////////////////////////////////////////////////${NC}    ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}                                                          ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}       ${IT}${VIL}╱╱  ██████╗  ██████╗ ██╗  ██╗  ╱╱${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}      ${IT}${VIL}╱╱  ██╔═══██╗██╔════╝ ██║  ██║  ╱╱${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}     ${IT}${VIL}╱╱   ██║   ██║██║  ███╗███████║  ╱╱${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}    ${IT}${VIL}╱╱    ██║   ██║██║   ██║██╔══██║  ╱╱${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}   ${IT}${VIL}╱╱     ╚██████╔╝╚██████╔╝██║  ██║  ╱╱${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}                                                          ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}          ${IT}${WHT}╱╱  ███████╗██╗██╗   ██╗  ╱╱${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}         ${IT}${WHT}╱╱  ╚══███╔╝██║██║   ██║  ╱╱${NC}               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}        ${IT}${WHT}╱╱     ███╔╝ ██║██║   ██║  ╱╱${NC}               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}       ${IT}${WHT}╱╱     ███╔╝  ██║╚██╗ ██╔╝  ╱╱${NC}               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}      ${IT}${WHT}╱╱     ███████╗██║ ╚████╔╝   ╱╱${NC}               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}                                                          ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${WHT}${D}////////////////////////////////////////////////////${NC}    ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}     ${IT}${VIL}✦ PREMIUM ZIVPN PANEL${NC}  ${D}·${NC}  ${D}fauzanihanipah/ziv-udp${NC}     ${VIO}║${NC}"
    echo -e "  ${VIO}╚══════════════════════════════════════════════════════════╝${NC}"
}

# ════════════════════════════════════════════════════════════════
#  INFO VPS
# ════════════════════════════════════════════════════════════════
draw_vps() {
    local ip;     ip=$(get_ip)
    local port;   port=$(get_port)
    local domain; domain=$(get_domain)
    local ram_u;  ram_u=$(free -m | awk '/^Mem/{print $3}')
    local ram_t;  ram_t=$(free -m | awk '/^Mem/{print $2}')
    local cpu;    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f",$2}' 2>/dev/null || echo "?")
    local du;     du=$(df -h / | awk 'NR==2{print $3}')
    local dt;     dt=$(df -h / | awk 'NR==2{print $2}')
    local os;     os=$(. /etc/os-release 2>/dev/null && echo "$NAME $VERSION_ID" || echo "Linux")
    local hn;     hn=$(hostname)
    local total;  total=$(total_user)
    local expc;   expc=$(exp_count)
    local now;    now=$(date "+%H:%M  %d/%m/%Y")

    local svc_ic svc_txt svc_col
    if is_up; then svc_col="${LG}"; svc_ic="🟢"; svc_txt="RUNNING"
    else           svc_col="${LR}"; svc_ic="🔴"; svc_txt="STOPPED"; fi

    local bot_txt="${LR}Belum setup${NC}"
    [[ -f "$BOTF" ]] && { source "$BOTF" 2>/dev/null; bot_txt="${LG}@${BOT_NAME}${NC}"; }

    local brand="OGH-ZIV"
    [[ -f "$STRF" ]] && { source "$STRF" 2>/dev/null; brand="${BRAND:-OGH-ZIV}"; }

    echo ""
    echo -e "  ${VIO}┌─────────────────────────────────────────────────────────┐${NC}"
    printf  "  ${VIO}│${NC}  ${BLD}${VIL}✦ INFO VPS${NC}  ${D}%45s${NC}  ${VIO}│${NC}\n" "$now"
    echo -e "  ${VIO}├──────────────────────────┬──────────────────────────────┤${NC}"
    printf  "  ${VIO}│${NC}  ${D}Hostname${NC} : ${W}%-15s${NC}  ${VIO}│${NC}  ${D}OS    ${NC}: ${W}%-20s${NC}  ${VIO}│${NC}\n" "$hn" "$os"
    printf  "  ${VIO}│${NC}  ${D}IP Publik${NC}: ${LC}%-15s${NC}  ${VIO}│${NC}  ${D}Domain${NC}: ${W}%-20s${NC}  ${VIO}│${NC}\n" "$ip" "$domain"
    printf  "  ${VIO}│${NC}  ${D}Port VPN${NC} : ${Y}%-15s${NC}  ${VIO}│${NC}  ${D}Brand ${NC}: ${VIL}%-20s${NC}  ${VIO}│${NC}\n" "$port" "$brand"
    echo -e "  ${VIO}├──────────────────────────┴──────────────────────────────┤${NC}"
    printf  "  ${VIO}│${NC}  ${D}CPU${NC}:${W}%s%%${NC}  ${D}RAM${NC}:${W}%s/%sMB${NC}  ${D}Disk${NC}:${W}%s/%s${NC}\n" "$cpu" "$ram_u" "$ram_t" "$du" "$dt"
    echo -e "  ${VIO}├─────────────────────────────────────────────────────────┤${NC}"
    printf  "  ${VIO}│${NC}  %s ZiVPN ${svc_col}%-8s${NC}  ${D}Akun:${NC}${W}%s${NC}  ${D}Expired:${NC}${LR}%s${NC}  ${D}Bot:${NC}$bot_txt\n" "$svc_ic" "$svc_txt" "$total" "$expc"
    echo -e "  ${VIO}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

show_header() {
    clear
    draw_logo
    draw_vps
}

# ════════════════════════════════════════════════════════════════
#  BINGKAI AKUN — CANTIK DAN RAPI
# ════════════════════════════════════════════════════════════════
show_akun_box() {
    local u="$1" p="$2" domain="$3" port="$4" ql="$5" exp="$6" note="$7"
    local sisa=$(( ($(date -d "$exp" +%s 2>/dev/null || echo 0) - $(date +%s)) / 86400 ))
    local sisa_str; [[ $sisa -lt 0 ]] && sisa_str="${LR}Expired${NC}" || sisa_str="${LG}${sisa} hari lagi${NC}"
    local brand="OGH-ZIV"
    [[ -f "$STRF" ]] && { source "$STRF" 2>/dev/null; brand="${BRAND:-OGH-ZIV}"; }

    echo ""
    echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
    printf  "  ${VIO}║${NC}  ${IT}${VIL}  ✦ %-50s${NC}  ${VIO}║${NC}\n" "$brand — AKUN UDP VPN PREMIUM"
    echo -e "  ${VIO}╠══════════════╦═══════════════════════════════════════════╣${NC}"
    printf  "  ${VIO}║${NC} ${D}  Username  ${NC} ${VIO}║${NC}  ${BLD}${W}%-41s${NC}  ${VIO}║${NC}\n" "$u"
    printf  "  ${VIO}║${NC} ${D}  Password  ${NC} ${VIO}║${NC}  ${BLD}${LC}%-41s${NC}  ${VIO}║${NC}\n" "$p"
    echo -e "  ${VIO}╠══════════════╬═══════════════════════════════════════════╣${NC}"
    printf  "  ${VIO}║${NC} ${D}  Host      ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "$domain"
    printf  "  ${VIO}║${NC} ${D}  Port      ${NC} ${VIO}║${NC}  ${Y}%-41s${NC}  ${VIO}║${NC}\n" "$port"
    printf  "  ${VIO}║${NC} ${D}  Obfs      ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "zivpn"
    echo -e "  ${VIO}╠══════════════╬═══════════════════════════════════════════╣${NC}"
    printf  "  ${VIO}║${NC} ${D}  Kuota     ${NC} ${VIO}║${NC}  ${LG}%-41s${NC}  ${VIO}║${NC}\n" "$ql"
    printf  "  ${VIO}║${NC} ${D}  Expired   ${NC} ${VIO}║${NC}  ${Y}%-41s${NC}  ${VIO}║${NC}\n" "$exp"
    printf  "  ${VIO}║${NC} ${D}  Sisa      ${NC} ${VIO}║${NC}  $sisa_str\n"
    [[ "$note" != "-" ]] && printf "  ${VIO}║${NC} ${D}  Pembeli   ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "$note"
    echo -e "  ${VIO}╠══════════════╩═══════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${D}📱 Download ZiVPN → Play Store / App Store${NC}             ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${D}⚠  Jangan share akun ini ke orang lain!${NC}               ${VIO}║${NC}"
    echo -e "  ${VIO}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ════════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════════
_reload_pw() {
    [[ ! -f "$UDB" || ! -f "$CFG" ]] && return
    local pws=()
    while IFS='|' read -r _ pw _ _ _; do pws+=("\"$pw\""); done < "$UDB"
    local pwl; pwl=$(IFS=','; echo "${pws[*]}")
    python3 - <<PYEOF 2>/dev/null
import json
with open('$CFG') as f: c=json.load(f)
c['auth']['config']=[${pwl}]
with open('$CFG','w') as f: json.dump(c,f,indent=2)
PYEOF
    systemctl restart zivpn &>/dev/null
}

_tg_send() {
    [[ ! -f "$BOTF" ]] && return
    source "$BOTF" 2>/dev/null
    [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]] && return
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" -d "text=$1" -d "parse_mode=HTML" &>/dev/null
}

_tg_raw() {
    local tok="$1" cid="$2" msg="$3"
    curl -s -X POST "https://api.telegram.org/bot${tok}/sendMessage" \
        -d "chat_id=${cid}" -d "text=${msg}" -d "parse_mode=HTML" &>/dev/null
}

# ════════════════════════════════════════════════════════════════
#  INSTALL
# ════════════════════════════════════════════════════════════════
do_install() {
    show_header
    echo -e "  ${VIO}┌─ 🚀  INSTALL ZIVPN ────────────────────────────────────┐${NC}"
    echo ""
    if [[ -f "$BIN" ]]; then
        warn "ZiVPN sudah terinstall."
        echo -ne "  Reinstall? [y/N]: "; read -r a
        [[ "$a" != [yY] ]] && return
    fi

    local sip; sip=$(get_ip)
    echo -ne "  ${LC}Domain / IP${NC}            : "; read -r inp_domain
    [[ -z "$inp_domain" ]] && inp_domain="$sip"
    echo -ne "  ${LC}Port${NC} [5667]             : "; read -r inp_port
    [[ -z "$inp_port" ]] && inp_port=5667
    echo -ne "  ${LC}Nama Brand / Toko${NC}       : "; read -r inp_brand
    [[ -z "$inp_brand" ]] && inp_brand="OGH-ZIV"
    echo -ne "  ${LC}Username Telegram Admin${NC}  : "; read -r inp_tg
    [[ -z "$inp_tg" ]] && inp_tg="-"

    echo ""
    echo -e "  ${VIO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    inf "Memulai instalasi ${VIL}OGH-ZIV Premium${NC}..."
    echo -e "  ${VIO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if command -v apt-get &>/dev/null; then
        apt-get update -qq &>/dev/null
        apt-get install -y -qq curl wget openssl python3 iptables &>/dev/null
    elif command -v yum &>/dev/null; then
        yum install -y -q curl wget openssl python3 iptables &>/dev/null
    fi
    ok "Dependensi terpasang"

    mkdir -p "$DIR"; touch "$UDB" "$LOG"
    echo "$inp_domain" > "$DOMF"
    printf "BRAND=%s\nADMIN_TG=%s\n" "$inp_brand" "$inp_tg" > "$STRF"
    ok "Direktori & konfigurasi dibuat"

    inf "Mengunduh binary ZiVPN..."
    wget -q --show-progress -O "$BIN" "$BINARY_URL"
    [[ $? -ne 0 ]] && { err "Gagal download binary!"; pause; return 1; }
    chmod +x "$BIN"
    ok "Binary ZiVPN siap"

    inf "Membuat sertifikat SSL..."
    openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
        -keyout "$DIR/zivpn.key" -out "$DIR/zivpn.crt" \
        -subj "/CN=$inp_domain" -days 3650 &>/dev/null
    ok "SSL Certificate (10 tahun) dibuat"

    cat > "$CFG" <<CFEOF
{
  "listen": ":${inp_port}",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": []
  }
}
CFEOF
    ok "config.json dibuat"

    cat > "$SVC" <<SVEOF
[Unit]
Description=OGH-ZIV UDP VPN Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$BIN server -c $CFG
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576
StandardOutput=append:$LOG
StandardError=append:$LOG

[Install]
WantedBy=multi-user.target
SVEOF

    systemctl daemon-reload
    systemctl enable zivpn &>/dev/null
    systemctl start zivpn
    ok "Service ZiVPN aktif & berjalan"

    command -v ufw &>/dev/null && {
        ufw allow "$inp_port/udp" &>/dev/null
        ufw allow "$inp_port/tcp" &>/dev/null
    }
    iptables -I INPUT -p udp --dport "$inp_port" -j ACCEPT 2>/dev/null
    iptables -I INPUT -p tcp --dport "$inp_port" -j ACCEPT 2>/dev/null
    ok "Firewall port $inp_port dibuka"

    echo ""
    echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${VIO}║${NC}  ${LG}${BLD}  ✦ OGH-ZIV PREMIUM BERHASIL DIINSTALL!${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════╦═══════════════════════════════════════════╣${NC}"
    printf  "  ${VIO}║${NC} ${D} Domain    ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "$inp_domain"
    printf  "  ${VIO}║${NC} ${D} Port      ${NC} ${VIO}║${NC}  ${Y}%-41s${NC}  ${VIO}║${NC}\n" "$inp_port"
    printf  "  ${VIO}║${NC} ${D} Brand     ${NC} ${VIO}║${NC}  ${VIL}%-41s${NC}  ${VIO}║${NC}\n" "$inp_brand"
    echo -e "  ${VIO}╚══════════════╩═══════════════════════════════════════════╝${NC}"
    pause
}

# ════════════════════════════════════════════════════════════════
#  USER FUNCTIONS
# ════════════════════════════════════════════════════════════════
u_add() {
    show_header
    echo -e "  ${VIO}┌─ ➕  ADD USER ──────────────────────────────────────────┐${NC}"
    echo ""
    echo -ne "  ${LC}Username${NC}                : "; read -r un
    [[ -z "$un" ]] && { err "Username kosong!"; pause; return; }
    grep -q "^${un}|" "$UDB" 2>/dev/null && { err "Username sudah ada!"; pause; return; }
    echo -ne "  ${LC}Password${NC} [auto]          : "; read -r up
    [[ -z "$up" ]] && up=$(rand_pass)
    echo -ne "  ${LC}Masa aktif (hari)${NC} [30]   : "; read -r ud
    [[ -z "$ud" ]] && ud=30
    local ue; ue=$(date -d "+${ud} days" +"%Y-%m-%d")
    echo -ne "  ${LC}Kuota GB${NC} (0=unlimited)   : "; read -r uq
    [[ -z "$uq" ]] && uq=0
    echo -ne "  ${LC}Catatan / Nama Pembeli${NC}   : "; read -r note
    [[ -z "$note" ]] && note="-"

    echo "${un}|${up}|${ue}|${uq}|${note}" >> "$UDB"
    _reload_pw

    local domain; domain=$(get_domain)
    local port;   port=$(get_port)
    local ql;     [[ "$uq" == "0" ]] && ql="Unlimited" || ql="${uq} GB"

    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
    _tg_send "✅ <b>Akun Baru — ${BRAND:-OGH-ZIV}</b>
┌──────────────────────────
│ 👤 <b>Username</b> : <code>$un</code>
│ 🔑 <b>Password</b> : <code>$up</code>
├──────────────────────────
│ 🌐 <b>Host</b>     : <code>$domain</code>
│ 🔌 <b>Port</b>     : <code>$port</code>
│ 📡 <b>Obfs</b>     : <code>zivpn</code>
├──────────────────────────
│ 📦 <b>Kuota</b>    : $ql
│ 📅 <b>Expired</b>  : $ue
│ 📝 <b>Pembeli</b>  : $note
└──────────────────────────"

    show_akun_box "$un" "$up" "$domain" "$port" "$ql" "$ue" "$note"
    pause
}

u_list() {
    show_header
    echo -e "  ${VIO}┌─ 📋  LIST AKUN ────────────────────────────────────────┐${NC}"
    echo ""
    [[ ! -s "$UDB" ]] && { warn "Belum ada akun terdaftar."; pause; return; }
    local today; today=$(date +"%Y-%m-%d"); local n=1
    echo -e "  ${VIO}┌────┬──────────────────┬────────────┬────────────┬───────┬─────────┐${NC}"
    printf  "  ${VIO}│${NC}${BLD} %-2s ${VIO}│${NC}${BLD} %-16s ${VIO}│${NC}${BLD} %-10s ${VIO}│${NC}${BLD} %-10s ${VIO}│${NC}${BLD} %-5s ${VIO}│${NC}${BLD} %-7s ${VIO}│${NC}\n" \
        "#" "Username" "Password" "Expired" "Kuota" "Status"
    echo -e "  ${VIO}├────┼──────────────────┼────────────┼────────────┼───────┼─────────┤${NC}"
    while IFS='|' read -r u p e q _; do
        local sc sl
        [[ "$e" < "$today" ]] && sc="$LR" sl="EXPIRED" || sc="$LG" sl="AKTIF  "
        local ql; [[ "$q" == "0" ]] && ql="Unlim" || ql="${q}GB   "
        printf "  ${VIO}│${NC} ${D}%-2s${NC} ${VIO}│${NC} ${W}%-16s${NC} ${VIO}│${NC} ${LC}%-10s${NC} ${VIO}│${NC} ${Y}%-10s${NC} ${VIO}│${NC} %-5s ${VIO}│${NC} ${sc}%-7s${NC} ${VIO}│${NC}\n" \
            "$n" "$u" "$p" "$e" "$ql" "$sl"
        ((n++))
    done < "$UDB"
    echo -e "  ${VIO}└────┴──────────────────┴────────────┴────────────┴───────┴─────────┘${NC}"
    echo ""
    echo -e "  ${D}  Total: $((n-1)) akun  │  Expired: $(exp_count) akun${NC}"
    pause
}

u_info() {
    show_header
    echo -e "  ${VIO}┌─ 🔍  INFO AKUN ────────────────────────────────────────┐${NC}"
    echo ""
    echo -ne "  ${LC}Username${NC}: "; read -r un
    local ln; ln=$(grep "^${un}|" "$UDB" 2>/dev/null)
    [[ -z "$ln" ]] && { err "User tidak ditemukan!"; pause; return; }
    IFS='|' read -r u p e q note <<< "$ln"
    local domain; domain=$(get_domain)
    local port;   port=$(get_port)
    local ql;     [[ "$q" == "0" ]] && ql="Unlimited" || ql="${q} GB"
    show_akun_box "$u" "$p" "$domain" "$port" "$ql" "$e" "$note"
    pause
}

u_del() {
    show_header
    echo -e "  ${VIO}┌─ 🗑️  DEL USER ─────────────────────────────────────────┐${NC}"
    echo ""
    [[ ! -s "$UDB" ]] && { warn "Tidak ada akun."; pause; return; }
    local n=1
    while IFS='|' read -r u _ e _ _; do
        printf "  ${D}%3s.${NC}  ${W}%-22s${NC}  ${D}exp: %s${NC}\n" "$n" "$u" "$e"; ((n++))
    done < "$UDB"
    echo ""
    echo -ne "  ${LC}Username yang dihapus${NC}: "; read -r du
    grep -q "^${du}|" "$UDB" 2>/dev/null || { err "User tidak ditemukan!"; pause; return; }
    sed -i "/^${du}|/d" "$UDB"
    _reload_pw
    _tg_send "🗑 <b>Akun Dihapus</b> : <code>$du</code>"
    ok "Akun '${W}$du${NC}' berhasil dihapus."
    pause
}

u_renew() {
    show_header
    echo -e "  ${VIO}┌─ 🔁  PERPANJANG AKUN ──────────────────────────────────┐${NC}"
    echo ""
    echo -ne "  ${LC}Username${NC}    : "; read -r ru
    grep -q "^${ru}|" "$UDB" 2>/dev/null || { err "User tidak ditemukan!"; pause; return; }
    echo -ne "  ${LC}Tambah hari${NC} : "; read -r rd; [[ -z "$rd" ]] && rd=30
    local ce; ce=$(grep "^${ru}|" "$UDB" | cut -d'|' -f3)
    local today; today=$(date +%Y-%m-%d)
    [[ "$ce" < "$today" ]] && ce="$today"
    local ne; ne=$(date -d "${ce} +${rd} days" +"%Y-%m-%d")
    sed -i "s/^\(${ru}|[^|]*|\)[^|]*/\1${ne}/" "$UDB"
    _tg_send "🔁 <b>Akun Diperpanjang</b>
👤 User     : <code>$ru</code>
📅 Expired  : <b>$ne</b>  (+${rd} hari)"
    echo ""
    echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${VIO}║${NC}  ${LG}✔  Akun berhasil diperpanjang!${NC}                        ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════╦═══════════════════════════════════════════╣${NC}"
    printf  "  ${VIO}║${NC} ${D} Username  ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "$ru"
    printf  "  ${VIO}║${NC} ${D} Expired   ${NC} ${VIO}║${NC}  ${Y}%-41s${NC}  ${VIO}║${NC}\n" "$ne"
    printf  "  ${VIO}║${NC} ${D} Tambahan  ${NC} ${VIO}║${NC}  ${LG}+%-40s${NC}  ${VIO}║${NC}\n" "${rd} hari"
    echo -e "  ${VIO}╚══════════════╩═══════════════════════════════════════════╝${NC}"
    pause
}

u_chpass() {
    show_header
    echo -e "  ${VIO}┌─ 🔑  GANTI PASSWORD ───────────────────────────────────┐${NC}"
    echo ""
    echo -ne "  ${LC}Username${NC}          : "; read -r pu
    grep -q "^${pu}|" "$UDB" 2>/dev/null || { err "User tidak ditemukan!"; pause; return; }
    echo -ne "  ${LC}Password baru${NC} [auto]: "; read -r pp
    [[ -z "$pp" ]] && pp=$(rand_pass)
    sed -i "s/^${pu}|[^|]*/${pu}|${pp}/" "$UDB"
    _reload_pw
    echo ""
    echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${VIO}║${NC}  ${LG}✔  Password berhasil diubah!${NC}                          ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════╦═══════════════════════════════════════════╣${NC}"
    printf  "  ${VIO}║${NC} ${D} Username  ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "$pu"
    printf  "  ${VIO}║${NC} ${D} Password  ${NC} ${VIO}║${NC}  ${LC}%-41s${NC}  ${VIO}║${NC}\n" "$pp"
    echo -e "  ${VIO}╚══════════════╩═══════════════════════════════════════════╝${NC}"
    pause
}

u_trial() {
    show_header
    echo -e "  ${VIO}┌─ 🎁  BUAT AKUN TRIAL ──────────────────────────────────┐${NC}"
    echo ""
    local tu="trial$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
    local tp; tp=$(rand_pass)
    local te; te=$(date -d "+1 day" +"%Y-%m-%d")
    echo "${tu}|${tp}|${te}|1|TRIAL" >> "$UDB"
    _reload_pw
    local domain; domain=$(get_domain); local port; port=$(get_port)
    _tg_send "🎁 <b>Akun Trial Dibuat</b>
👤 User  : <code>$tu</code>
🔑 Pass  : <code>$tp</code>
📅 Exp   : $te  (1 hari / 1 GB)"
    show_akun_box "$tu" "$tp" "$domain" "$port" "1 GB" "$te" "TRIAL"
    pause
}

u_clean() {
    show_header
    echo -e "  ${VIO}┌─ 🧹  HAPUS AKUN EXPIRED ───────────────────────────────┐${NC}"
    echo ""
    local today; today=$(date +%Y-%m-%d); local cnt=0
    while IFS='|' read -r u _ e _ _; do
        if [[ "$e" < "$today" ]]; then
            sed -i "/^${u}|/d" "$UDB"
            ok "Dihapus: ${W}$u${NC}  ${D}(exp: $e)${NC}"; ((cnt++))
        fi
    done < <(cat "$UDB" 2>/dev/null)
    echo ""
    [[ $cnt -gt 0 ]] && { _reload_pw; ok "Total ${W}$cnt${NC} akun expired dihapus."; } \
                     || inf "Tidak ada akun expired."
    pause
}

# ════════════════════════════════════════════════════════════════
#  JUALAN
# ════════════════════════════════════════════════════════════════
t_akun() {
    show_header
    echo -e "  ${VIO}┌─ 📨  TEMPLATE PESAN AKUN ──────────────────────────────┐${NC}"
    echo ""
    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
    echo -ne "  ${LC}Username${NC}: "; read -r tu
    local ln; ln=$(grep "^${tu}|" "$UDB" 2>/dev/null)
    [[ -z "$ln" ]] && { err "User tidak ditemukan!"; pause; return; }
    IFS='|' read -r u p e q note <<< "$ln"
    local domain; domain=$(get_domain); local port; port=$(get_port)
    local ql; [[ "$q" == "0" ]] && ql="Unlimited" || ql="${q} GB"
    show_akun_box "$u" "$p" "$domain" "$port" "$ql" "$e" "$note"
    pause
}

set_store() {
    show_header
    echo -e "  ${VIO}┌─ ⚙️  PENGATURAN TOKO ───────────────────────────────────┐${NC}"
    echo ""
    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
    echo -ne "  ${LC}Nama Brand${NC} [${BRAND:-OGH-ZIV}]  : "; read -r ib
    echo -ne "  ${LC}Username TG Admin${NC} [${ADMIN_TG:--}]: "; read -r it
    printf "BRAND=%s\nADMIN_TG=%s\n" "${ib:-${BRAND:-OGH-ZIV}}" "${it:-${ADMIN_TG:--}}" > "$STRF"
    ok "Pengaturan toko disimpan!"
    pause
}

# ════════════════════════════════════════════════════════════════
#  TELEGRAM BOT
# ════════════════════════════════════════════════════════════════
tg_setup() {
    show_header
    echo -e "  ${VIO}┌─ 🤖  SETUP BOT TELEGRAM ───────────────────────────────┐${NC}"
    echo ""
    inf "Buka ${LC}@BotFather${NC} di Telegram → ketik /newbot → salin TOKEN"
    inf "Kirim /start ke bot → buka URL:"
    echo -e "  ${D}     api.telegram.org/bot<TOKEN>/getUpdates${NC}"
    echo ""
    echo -ne "  ${LC}Bot Token${NC}     : "; read -r tok
    [[ -z "$tok" ]] && { err "Token kosong!"; pause; return; }
    echo -ne "  ${LC}Chat ID Admin${NC} : "; read -r cid
    [[ -z "$cid" ]] && { err "Chat ID kosong!"; pause; return; }

    local res; res=$(curl -s "https://api.telegram.org/bot${tok}/getMe")
    if echo "$res" | grep -q '"ok":true'; then
        local bname; bname=$(echo "$res" | python3 -c \
            "import sys,json;d=json.load(sys.stdin);print(d['result']['username'])" 2>/dev/null)
        printf "BOT_TOKEN=%s\nCHAT_ID=%s\nBOT_NAME=%s\n" "$tok" "$cid" "$bname" > "$BOTF"
        _tg_raw "$tok" "$cid" "✅ <b>OGH-ZIV Premium</b> bot terhubung ke server VPS!"
        echo ""
        echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${VIO}║${NC}  ${LG}✔  Bot Telegram berhasil terhubung!${NC}                   ${VIO}║${NC}"
        echo -e "  ${VIO}╠══════════════╦═══════════════════════════════════════════╣${NC}"
        printf  "  ${VIO}║${NC} ${D} Bot Name  ${NC} ${VIO}║${NC}  ${W}@%-40s${NC}  ${VIO}║${NC}\n" "$bname"
        printf  "  ${VIO}║${NC} ${D} Chat ID   ${NC} ${VIO}║${NC}  ${Y}%-41s${NC}  ${VIO}║${NC}\n" "$cid"
        echo -e "  ${VIO}╚══════════════╩═══════════════════════════════════════════╝${NC}"
    else
        err "Token tidak valid atau tidak bisa terhubung!"
    fi
    pause
}

tg_status() {
    show_header
    echo -e "  ${VIO}┌─ 📡  STATUS BOT TELEGRAM ──────────────────────────────┐${NC}"
    echo ""
    if [[ ! -f "$BOTF" ]]; then
        warn "Bot belum dikonfigurasi."
        echo -ne "  Setup sekarang? [y/N]: "; read -r a
        [[ "$a" == [yY] ]] && tg_setup; return
    fi
    source "$BOTF" 2>/dev/null
    local res; res=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")
    if echo "$res" | grep -q '"ok":true'; then
        local fn; fn=$(echo "$res" | python3 -c \
            "import sys,json;d=json.load(sys.stdin);print(d['result']['first_name'])" 2>/dev/null)
        echo ""
        echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${VIO}║${NC}  ${LG}🟢  Bot Aktif & Terhubung${NC}                              ${VIO}║${NC}"
        echo -e "  ${VIO}╠══════════════╦═══════════════════════════════════════════╣${NC}"
        printf  "  ${VIO}║${NC} ${D} Nama      ${NC} ${VIO}║${NC}  ${W}%-41s${NC}  ${VIO}║${NC}\n" "$fn"
        printf  "  ${VIO}║${NC} ${D} Username  ${NC} ${VIO}║${NC}  ${W}@%-40s${NC}  ${VIO}║${NC}\n" "$BOT_NAME"
        printf  "  ${VIO}║${NC} ${D} Chat ID   ${NC} ${VIO}║${NC}  ${Y}%-41s${NC}  ${VIO}║${NC}\n" "$CHAT_ID"
        echo -e "  ${VIO}╚══════════════╩═══════════════════════════════════════════╝${NC}"
        echo ""
        echo -ne "  ${LC}Kirim pesan test?${NC} [y/N]: "; read -r ts
        [[ "$ts" == [yY] ]] && {
            _tg_send "🟢 <b>Test OGH-ZIV Premium</b> — Bot berjalan normal! ✅"
            ok "Pesan test dikirim ke Telegram!"
        }
    else
        err "Bot tidak dapat terhubung. Cek token!"
    fi
    pause
}

tg_kirim_akun() {
    show_header
    echo -e "  ${VIO}┌─ 📤  KIRIM AKUN KE TELEGRAM ───────────────────────────┐${NC}"
    echo ""
    [[ ! -f "$BOTF" ]] && { err "Bot belum dikonfigurasi!"; pause; return; }
    source "$BOTF" 2>/dev/null
    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null

    echo -ne "  ${LC}Username akun${NC}    : "; read -r su
    local ln; ln=$(grep "^${su}|" "$UDB" 2>/dev/null)
    [[ -z "$ln" ]] && { err "User tidak ditemukan!"; pause; return; }
    IFS='|' read -r u p e q note <<< "$ln"

    echo -ne "  ${LC}Chat ID tujuan${NC} [$CHAT_ID]: "; read -r did
    [[ -z "$did" ]] && did="$CHAT_ID"

    local domain; domain=$(get_domain); local port; port=$(get_port)
    local ql; [[ "$q" == "0" ]] && ql="Unlimited" || ql="${q} GB"
    local sisa=$(( ($(date -d "$e" +%s 2>/dev/null || echo 0) - $(date +%s)) / 86400 ))
    local sisa_str; [[ $sisa -lt 0 ]] && sisa_str="Expired" || sisa_str="${sisa} hari lagi"

    local msg="🔒 <b>${BRAND:-OGH-ZIV} — Akun VPN UDP Premium</b>

┌────────────────────────────
│ 👤 <b>Username</b>  : <code>$u</code>
│ 🔑 <b>Password</b>  : <code>$p</code>
├────────────────────────────
│ 🌐 <b>Host</b>      : <code>$domain</code>
│ 🔌 <b>Port</b>      : <code>$port</code>
│ 📡 <b>Obfs</b>      : <code>zivpn</code>
├────────────────────────────
│ 📦 <b>Kuota</b>     : $ql
│ 📅 <b>Expired</b>   : $e
│ ⏳ <b>Sisa</b>      : $sisa_str
└────────────────────────────

📱 Download <b>ZiVPN</b> di Play Store / App Store
⚠️ Jangan share akun ini ke orang lain!"

    local r; r=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${did}" -d "text=${msg}" -d "parse_mode=HTML")
    echo ""
    echo "$r" | grep -q '"ok":true' \
        && ok "Akun '${W}$u${NC}' berhasil dikirim ke Telegram!" \
        || err "Gagal kirim! Periksa Chat ID atau token."
    pause
}

tg_broadcast() {
    show_header
    echo -e "  ${VIO}┌─ 📢  BROADCAST PESAN ──────────────────────────────────┐${NC}"
    echo ""
    [[ ! -f "$BOTF" ]] && { err "Bot belum dikonfigurasi!"; pause; return; }
    source "$BOTF" 2>/dev/null
    echo -e "  ${D}Ketik pesan. Ketik ${W}SELESAI${D} di baris baru untuk kirim.${NC}"
    echo ""
    local msg="" line
    while IFS= read -r line; do
        [[ "$line" == "SELESAI" ]] && break
        msg+="$line
"
    done
    [[ -z "$msg" ]] && { err "Pesan kosong!"; pause; return; }
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" -d "text=${msg}" &>/dev/null
    ok "Broadcast berhasil dikirim!"
    pause
}

tg_guide() {
    show_header
    echo -e "  ${VIO}┌─ 📖  PANDUAN BUAT BOT TELEGRAM ────────────────────────┐${NC}"
    echo ""
    echo -e "  ${VIO}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${VIO}║${NC}  ${Y}LANGKAH 1 — Buat Bot di BotFather${NC}                      ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${W}1.${NC} Buka Telegram → cari ${LC}@BotFather${NC}                       ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}2.${NC} Kirim perintah ${Y}/newbot${NC}                               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}3.${NC} Masukkan nama bot → contoh: ${W}OGH ZIV VPN${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}4.${NC} Masukkan username (harus akhiran ${Y}bot${NC})                ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}     Contoh: ${W}oghziv_vpn_bot${NC}                                ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}5.${NC} Salin ${Y}TOKEN${NC} yang diberikan BotFather              ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${Y}LANGKAH 2 — Ambil Chat ID${NC}                               ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${W}1.${NC} Kirim ${Y}/start${NC} ke bot kamu di Telegram               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}2.${NC} Buka URL ini di browser:                              ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}     ${D}api.telegram.org/bot<TOKEN>/getUpdates${NC}               ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}3.${NC} Cari nilai ${Y}\"id\"${NC} di bagian ${Y}\"from\"${NC}                  ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}4.${NC} Angka tersebut = ${Y}Chat ID${NC} kamu                      ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${Y}LANGKAH 3 — Hubungkan ke OGH-ZIV${NC}                        ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${W}1.${NC} Menu Telegram → ${LC}[1] Setup / Konfigurasi Bot${NC}         ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}2.${NC} Masukkan Token dan Chat ID                           ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${W}3.${NC} ${LG}✅ Selesai! Notifikasi otomatis aktif${NC}              ${VIO}║${NC}"
    echo -e "  ${VIO}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${VIO}║${NC}  ${Y}Tips Perintah BotFather:${NC}                                 ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  /setdescription · /setuserpic · /setcommands · /mybots ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}                                                          ${VIO}║${NC}"
    echo -e "  ${VIO}║${NC}  ${LC}https://t.me/BotFather${NC}                                   ${VIO}║${NC}"
    echo -e "  ${VIO}╚══════════════════════════════════════════════════════════╝${NC}"
    pause
}

# ════════════════════════════════════════════════════════════════
#  SERVICE
# ════════════════════════════════════════════════════════════════
svc_status() {
    show_header
    echo -e "  ${VIO}┌─ 🖥️  STATUS SERVICE ────────────────────────────────────┐${NC}"
    echo ""
    systemctl status zivpn --no-pager -l
    pause
}

svc_bandwidth() {
    show_header
    echo -e "  ${VIO}┌─ 📊  BANDWIDTH / KONEKSI AKTIF ────────────────────────┐${NC}"
    echo ""
    local port; port=$(get_port)
    inf "Koneksi aktif ke port ${Y}$port${NC}:"
    echo ""
    ss -u -n -p 2>/dev/null | grep ":$port" || inf "Tidak ada koneksi UDP aktif saat ini."
    echo ""
    inf "Statistik network:"
    cat /proc/net/dev 2>/dev/null | awk 'NR>2{
        split($1,a,":");
        gsub(/[[:space:]]/,"",a[1]);
        if(a[1]!="lo") printf "  %-12s RX: %-12s TX: %s\n", a[1], $2, $10
    }' | head -5
    pause
}

svc_log() {
    show_header
    echo -e "  ${VIO}┌─ 📄  LOG ZIVPN ────────────────────────────────────────┐${NC}"
    echo ""
    [[ -f "$LOG" ]] && tail -60 "$LOG" || journalctl -u zivpn -n 60 --no-pager
    pause
}

svc_port() {
    show_header
    echo -e "  ${VIO}┌─ 🔧  GANTI PORT ───────────────────────────────────────┐${NC}"
    echo ""
    local cp; cp=$(get_port)
    echo -e "  Port saat ini : ${Y}$cp${NC}"
    echo -ne "  ${LC}Port baru${NC}     : "; read -r np
    [[ ! "$np" =~ ^[0-9]+$ || $np -lt 1 || $np -gt 65535 ]] && { err "Port tidak valid!"; pause; return; }
    sed -i "s/\"listen\": *\":${cp}\"/\"listen\": \":${np}\"/" "$CFG"
    command -v ufw &>/dev/null && { ufw delete allow "$cp/udp" &>/dev/null; ufw allow "$np/udp" &>/dev/null; }
    iptables -D INPUT -p udp --dport "$cp" -j ACCEPT 2>/dev/null
    iptables -I INPUT -p udp --dport "$np" -j ACCEPT 2>/dev/null
    systemctl restart zivpn
    ok "Port diubah: ${Y}$cp${NC} → ${LG}$np${NC}"
    pause
}

svc_backup() {
    show_header
    echo -e "  ${VIO}┌─ 💾  BACKUP DATA ───────────────────────────────────────┐${NC}"
    echo ""
    local bfile="/root/oghziv-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    inf "Membuat backup → ${W}$bfile${NC}"
    tar -czf "$bfile" "$DIR" 2>/dev/null
    [[ $? -eq 0 ]] && ok "Backup berhasil: ${W}$bfile${NC}" || err "Backup gagal!"
    pause
}

svc_restore() {
    show_header
    echo -e "  ${VIO}┌─ ♻️  RESTORE DATA ──────────────────────────────────────┐${NC}"
    echo ""
    echo -ne "  ${LC}Path file backup (.tar.gz)${NC}: "; read -r bpath
    [[ ! -f "$bpath" ]] && { err "File tidak ditemukan!"; pause; return; }
    warn "Restore akan menimpa semua data saat ini!"
    echo -ne "  Lanjutkan? [y/N]: "; read -r cf
    [[ "$cf" != [yY] ]] && { inf "Dibatalkan."; pause; return; }
    tar -xzf "$bpath" -C / 2>/dev/null
    _reload_pw
    ok "Restore berhasil!"
    pause
}

# ════════════════════════════════════════════════════════════════
#  UNINSTALL
# ════════════════════════════════════════════════════════════════
do_uninstall() {
    show_header
    echo -e "  ${VIO}┌─ ⚠️  UNINSTALL ─────────────────────────────────────────┐${NC}"
    echo ""
    warn "Semua data user & konfigurasi akan DIHAPUS PERMANEN!"
    echo -ne "  ${LR}Ketik 'HAPUS' untuk konfirmasi${NC}: "; read -r cf
    [[ "$cf" != "HAPUS" ]] && { inf "Dibatalkan."; pause; return; }
    systemctl stop zivpn 2>/dev/null
    systemctl disable zivpn 2>/dev/null
    rm -f "$SVC" "$BIN"
    rm -rf "$DIR"
    systemctl daemon-reload
    ok "OGH-ZIV Premium berhasil diuninstall."
    pause
}

# ════════════════════════════════════════════════════════════════
#  HELPER PANEL BUTTONS — GAYA TELEGRAM
# ════════════════════════════════════════════════════════════════
_top()  { echo -e "  ${VIO}╔══════════════════════════════════════════════════════╗${NC}"; }
_bot()  { echo -e "  ${VIO}╚══════════════════════════════════════════════════════╝${NC}"; }
_sep()  { echo -e "  ${VIO}╠══════════════════════════════════════════════════════╣${NC}"; }
_sep2() { echo -e "  ${VIO}╠═══════════════════════╬══════════════════════════════╣${NC}"; }
_btn()  { printf  "  ${VIO}║${NC} ${2:-$W}%-52s${NC} ${VIO}║${NC}\n" "$1"; }
_btn2() { printf  "  ${VIO}║${NC} ${3:-$LC}%-23s${NC} ${VIO}║${NC} ${4:-$LC}%-26s${NC} ${VIO}║${NC}\n" "$1" "$2"; }

# ════════════════════════════════════════════════════════════════
#  SUB MENUS
# ════════════════════════════════════════════════════════════════
menu_jualan() {
    while true; do
        show_header
        [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
        _top
        _btn "  ${IT}${VIL}✦ MENU JUALAN${NC}" "$NC"
        _sep
        _btn "  📨  [1]  Template Pesan Akun" "$LC"
        _sep
        _btn "  📤  [2]  Kirim Akun via Telegram" "$LC"
        _sep
        _btn "  ⚙️   [3]  Pengaturan Toko" "$Y"
        _sep
        _btn "  ◀   [0]  Kembali" "$LR"
        _bot
        echo ""
        printf "  ${D}Brand: ${VIL}%-20s${D}  TG: @%s${NC}\n" "${BRAND:-OGH-ZIV}" "${ADMIN_TG:--}"
        echo ""
        echo -ne "  ${VIO}›${NC} "; read -r ch
        case $ch in
            1) t_akun ;; 2) tg_kirim_akun ;; 3) set_store ;;
            0) break ;; *) warn "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

menu_telegram() {
    while true; do
        show_header
        local bstat="${LR}Belum dikonfigurasi${NC}"
        [[ -f "$BOTF" ]] && { source "$BOTF" 2>/dev/null; bstat="${LG}@${BOT_NAME}${NC}"; }
        _top
        _btn "  ${IT}${VIL}✦ TELEGRAM BOT${NC}" "$NC"
        _sep
        printf "  ${VIO}║${NC}  ${D}Status :${NC} $bstat\n"
        _sep
        _btn "  🔧  [1]  Setup / Konfigurasi Bot" "$LC"
        _sep
        _btn "  📡  [2]  Cek Status Bot" "$LC"
        _sep
        _btn "  📤  [3]  Kirim Akun ke Telegram" "$LC"
        _sep
        _btn "  📢  [4]  Broadcast Pesan" "$Y"
        _sep
        _btn "  📖  [5]  Panduan Buat Bot Telegram" "$Y"
        _sep
        _btn "  ◀   [0]  Kembali" "$LR"
        _bot
        echo ""
        echo -ne "  ${VIO}›${NC} "; read -r ch
        case $ch in
            1) tg_setup ;; 2) tg_status ;;    3) tg_kirim_akun ;;
            4) tg_broadcast ;; 5) tg_guide ;;
            0) break ;; *) warn "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

menu_service() {
    while true; do
        show_header
        _top
        _btn "  ${IT}${VIL}✦ MANAJEMEN SERVICE${NC}" "$NC"
        _sep
        _btn "  🖥️   [1]  Status Service" "$LC"
        _sep
        _btn2 "  ▶   [2]  Start ZiVPN" "  ⏹   [3]  Stop ZiVPN" "$LG" "$LR"
        _sep2
        _btn "  🔄  [4]  Restart ZiVPN" "$Y"
        _sep
        _btn "  📄  [5]  Lihat Log" "$LC"
        _sep
        _btn "  🔧  [6]  Ganti Port" "$Y"
        _sep
        _btn "  💾  [7]  Backup Data" "$M"
        _sep
        _btn "  ♻️   [8]  Restore Data" "$M"
        _sep
        _btn "  ◀   [0]  Kembali" "$LR"
        _bot
        echo ""
        echo -ne "  ${VIO}›${NC} "; read -r ch
        case $ch in
            1) svc_status ;;
            2) systemctl start zivpn; ok "ZiVPN dijalankan."; pause ;;
            3) systemctl stop zivpn; ok "ZiVPN dihentikan."; pause ;;
            4) systemctl restart zivpn; sleep 1
               is_up && ok "Restart berhasil!" || err "Gagal restart!"; pause ;;
            5) svc_log ;; 6) svc_port ;;
            7) svc_backup ;; 8) svc_restore ;;
            0) break ;; *) warn "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════
#  MENU UTAMA — GAYA TELEGRAM PREMIUM PANEL
# ════════════════════════════════════════════════════════════════
main_menu() {
    while true; do
        show_header
        _top
        _btn "  ${IT}${VIL}  ✦ PREMIUM ZIVPN PANEL  ✦${NC}" "$NC"
        _btn "  ${D}Pilih menu di bawah 👇${NC}" "$NC"
        _sep
        _btn2 "  📋  [1]  List Akun" "  🖥️  [2]  Status VPS" "$LC" "$LC"
        _sep2
        _btn2 "  📊  [3]  Bandwidth" "  💾  [4]  Backup" "$LC" "$LC"
        _sep2
        _btn "  ♻️   [5]  Restore" "$LC"
        _sep
        _btn "  🔄  [6]  Restart Service" "$Y"
        _sep
        _btn2 "  ➕  [7]  Add User" "  🗑️  [8]  Del User" "$LG" "$LR"
        _sep2
        _btn "  🔁  [9]  Perpanjang Akun" "$LC"
        _sep
        _btn "  🛒  [A]  Menu Jualan" "$VIL"
        _sep
        _btn "  🤖  [B]  Telegram Bot" "$VIL"
        _sep
        _btn "  ⚙️   [C]  Manajemen Service" "$Y"
        _sep
        _btn "  🚀  [D]  Install ZiVPN" "$LG"
        _sep
        _btn "  🗑️   [E]  Uninstall ZiVPN" "$LR"
        _sep
        _btn "  ◀   [0]  Keluar" "$LR"
        _bot
        echo ""
        echo -ne "  ${VIO}›${NC} "
        read -r ch
        case ${ch,,} in
            1) u_list ;;      2) svc_status ;;      3) svc_bandwidth ;;
            4) svc_backup ;;  5) svc_restore ;;
            6) systemctl restart zivpn; sleep 1
               is_up && ok "Service berhasil direstart!" || err "Gagal restart!"; pause ;;
            7) u_add ;;       8) u_del ;;            9) u_renew ;;
            a) menu_jualan ;;  b) menu_telegram ;;   c) menu_service ;;
            d) do_install ;;   e) do_uninstall ;;
            0) echo -e "\n  ${IT}${VIL}Sampai jumpa! — OGH-ZIV Premium${NC}\n"; exit 0 ;;
            *) warn "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

check_root
main_menu
