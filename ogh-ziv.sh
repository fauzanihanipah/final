#!/bin/bash
# ================================================================
#   OGH-ZIV — UDP VPN MANAGER
#   Binary  : github.com/fauzanihanipah/ziv-udp
#   Config  : github.com/fauzanihanipah/ziv-udp/raw/main/config.json
# ================================================================

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; M='\033[0;35m'; W='\033[1;37m'
D='\033[2m'; BLD='\033[1m'; NC='\033[0m'

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
check_root() { [[ $EUID -ne 0 ]] && { echo -e "\n${R}Jalankan sebagai root!${NC}\n"; exit 1; }; }
ok()    { echo -e "  ${G}[✔]${NC} $*"; }
inf()   { echo -e "  ${C}[i]${NC} $*"; }
warn()  { echo -e "  ${Y}[!]${NC} $*"; }
err()   { echo -e "  ${R}[✘]${NC} $*"; }
hr()    { echo -e "  ${D}──────────────────────────────────────────────────────────${NC}"; }
pause() { echo ""; echo -ne "  ${D}[ Enter ] kembali...${NC}"; read -r; }

get_ip()     { curl -s4 --max-time 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'; }
get_port()   { grep -o '"listen":":[0-9]*"\|"listen": *":[0-9]*"' "$CFG" 2>/dev/null | grep -o '[0-9]*' || echo "5667"; }
get_domain() { cat "$DOMF" 2>/dev/null || get_ip; }
is_up()      { systemctl is-active --quiet zivpn 2>/dev/null; }
total_user() { [[ -f "$UDB" ]] && grep -c '' "$UDB" 2>/dev/null || echo 0; }
exp_count()  {
    local t; t=$(date +%Y-%m-%d)
    [[ -f "$UDB" ]] && awk -F'|' -v d="$t" '$3<d{c++}END{print c+0}' "$UDB" || echo 0
}
rand_pass()  { tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10; }

# ── LOGO OGH-ZIV ─────────────────────────────────────────────────
draw_logo() {
    echo -e ""
    echo -e "  ${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${C}║${NC}                                                          ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${W}  ██████╗  ██████╗ ██╗  ██╗${NC}                            ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${W} ██╔═══██╗██╔════╝ ██║  ██║${NC}                            ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${C} ██║   ██║██║  ███╗███████║${NC}  ${BLD}${Y}███████╗██╗██╗   ██╗${NC}  ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${C} ██║   ██║██║   ██║██╔══██║${NC}  ${BLD}${Y}╚══███╔╝██║██║   ██║${NC}  ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${W} ╚██████╔╝╚██████╔╝██║  ██║${NC}  ${BLD}${W}  ███╔╝ ██║╚██╗ ██╔╝${NC}  ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${W}  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝${NC}  ${BLD}${W} ███████╗██║ ╚████╔╝ ${NC}  ${C}║${NC}"
    echo -e "  ${C}║${NC}  ${BLD}${W}                             ${NC}  ${BLD}${W} ╚══════╝╚═╝  ╚═══╝  ${NC}  ${C}║${NC}"
    echo -e "  ${C}║${NC}                                                          ${C}║${NC}"
    echo -e "  ${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${C}║${NC}  ${Y}★${NC} ${BLD}UDP VPN Manager${NC}  ${D}·${NC}  ${C}fauzanihanipah/ziv-udp${NC}          ${C}║${NC}"
    echo -e "  ${C}╚══════════════════════════════════════════════════════════╝${NC}"
}

# ── INFO VPS ─────────────────────────────────────────────────────
draw_vps() {
    local ip;      ip=$(get_ip)
    local port;    port=$(get_port)
    local domain;  domain=$(get_domain)
    local ram_u;   ram_u=$(free -m | awk '/^Mem/{print $3}')
    local ram_t;   ram_t=$(free -m | awk '/^Mem/{print $2}')
    local cpu;     cpu=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f", $2}' 2>/dev/null || echo "?")
    local disk_u;  disk_u=$(df -h / | awk 'NR==2{print $3}')
    local disk_t;  disk_t=$(df -h / | awk 'NR==2{print $2}')
    local os;      os=$(. /etc/os-release 2>/dev/null && echo "$NAME $VERSION_ID" || echo "Linux")
    local host_n;  host_n=$(hostname)
    local total;   total=$(total_user)
    local expc;    expc=$(exp_count)

    local svc_txt svc_col
    if is_up; then svc_col="$G"; svc_txt="● RUNNING"
    else           svc_col="$R"; svc_txt="● STOPPED"; fi

    local bot_txt="${R}Belum setup${NC}"
    if [[ -f "$BOTF" ]]; then
        source "$BOTF" 2>/dev/null
        bot_txt="${G}@${BOT_NAME:-bot}${NC}"
    fi

    local brand_txt="OGH-ZIV"
    [[ -f "$STRF" ]] && { source "$STRF" 2>/dev/null; brand_txt="${BRAND:-OGH-ZIV}"; }

    echo ""
    echo -e "  ${C}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${C}│${NC}  ${BLD}${W}INFO VPS${NC}                       ${D}Brand:${NC} ${W}$brand_txt${NC}"
    echo -e "  ${C}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${C}│${NC}  ${D}Hostname ${NC}: ${W}$host_n${NC}"
    echo -e "  ${C}│${NC}  ${D}OS       ${NC}: ${W}$os${NC}"
    echo -e "  ${C}│${NC}  ${D}IP Publik${NC}: ${W}$ip${NC}"
    echo -e "  ${C}│${NC}  ${D}Domain   ${NC}: ${W}$domain${NC}"
    echo -e "  ${C}│${NC}  ${D}Port VPN ${NC}: ${W}$port${NC}"
    echo -e "  ${C}├─────────────────────────────────────────────────────────┤${NC}"
    printf   "  ${C}│${NC}  ${D}CPU      ${NC}: ${W}%-8s%%${NC}  ${D}RAM${NC}: ${W}%s / %s MB${NC}\n" "$cpu" "$ram_u" "$ram_t"
    echo -e "  ${C}│${NC}  ${D}Disk     ${NC}: ${W}$disk_u / $disk_t${NC}"
    echo -e "  ${C}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${C}│${NC}  ${D}ZiVPN    ${NC}: ${svc_col}$svc_txt${NC}   ${D}Akun:${NC} ${W}$total${NC}  ${D}Expired:${NC} ${R}$expc${NC}"
    echo -e "  ${C}│${NC}  ${D}Telegram ${NC}: $bot_txt"
    echo -e "  ${C}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

show_header() {
    clear
    draw_logo
    draw_vps
}

# ════════════════════════════════════════════════════════════════
#  INSTALL
# ════════════════════════════════════════════════════════════════
do_install() {
    show_header
    echo -e "  ${BLD}${W}── INSTALL ZIVPN ───────────────────────────────────────────${NC}"
    echo ""

    if [[ -f "$BIN" ]]; then
        warn "ZiVPN sudah terinstall."
        echo -ne "  Reinstall? [y/N]: "; read -r a
        [[ "$a" != [yY] ]] && return
    fi

    local sip; sip=$(get_ip)
    echo -ne "  ${C}Domain / IP${NC} [$sip]: "; read -r inp_domain
    [[ -z "$inp_domain" ]] && inp_domain="$sip"

    echo -ne "  ${C}Port${NC} [5667]: "; read -r inp_port
    [[ -z "$inp_port" ]] && inp_port=5667

    echo -ne "  ${C}Nama Brand / Toko${NC} [OGH-ZIV]: "; read -r inp_brand
    [[ -z "$inp_brand" ]] && inp_brand="OGH-ZIV"

    echo -ne "  ${C}Username Telegram Admin${NC} [-]: "; read -r inp_tg
    [[ -z "$inp_tg" ]] && inp_tg="-"

    echo ""
    inf "Memulai instalasi..."

    if command -v apt-get &>/dev/null; then
        apt-get update -qq &>/dev/null
        apt-get install -y -qq curl wget openssl python3 &>/dev/null
    elif command -v yum &>/dev/null; then
        yum install -y -q curl wget openssl python3 &>/dev/null
    fi
    ok "Dependensi siap"

    mkdir -p "$DIR"
    touch "$UDB" "$LOG"
    echo "$inp_domain" > "$DOMF"

    cat > "$STRF" <<STEOF
BRAND=$inp_brand
ADMIN_TG=$inp_tg
STEOF
    ok "Konfigurasi toko disimpan"

    inf "Mengunduh binary..."
    wget -q --show-progress -O "$BIN" "$BINARY_URL"
    if [[ $? -ne 0 ]]; then
        err "Gagal download binary!"; pause; return 1
    fi
    chmod +x "$BIN"
    ok "Binary siap"

    inf "Generate SSL (10 tahun)..."
    openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
        -keyout "$DIR/zivpn.key" -out "$DIR/zivpn.crt" \
        -subj "/CN=$inp_domain" -days 3650 &>/dev/null
    ok "Sertifikat SSL dibuat"

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
Description=OGH-ZIV UDP Service
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
    ok "Service ZiVPN aktif"

    command -v ufw &>/dev/null && {
        ufw allow "$inp_port/udp" &>/dev/null
        ufw allow "$inp_port/tcp" &>/dev/null
    }
    iptables -I INPUT -p udp --dport "$inp_port" -j ACCEPT 2>/dev/null
    iptables -I INPUT -p tcp --dport "$inp_port" -j ACCEPT 2>/dev/null
    ok "Port $inp_port dibuka"

    echo ""
    echo -e "  ${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${C}║${NC}  ${G}${BLD}✔  OGH-ZIV BERHASIL DIINSTALL!${NC}                        ${C}║${NC}"
    echo -e "  ${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${C}║${NC}  Domain  : ${W}$inp_domain${NC}"
    echo -e "  ${C}║${NC}  Port    : ${W}$inp_port${NC}"
    echo -e "  ${C}║${NC}  Brand   : ${W}$inp_brand${NC}"
    echo -e "  ${C}╚══════════════════════════════════════════════════════════╝${NC}"
    pause
}

# ════════════════════════════════════════════════════════════════
#  USER HELPERS
# ════════════════════════════════════════════════════════════════
_reload_pw() {
    [[ ! -f "$UDB" || ! -f "$CFG" ]] && return
    local pws=()
    while IFS='|' read -r _ pw _ _ _; do
        pws+=("\"$pw\"")
    done < "$UDB"
    local pwl; pwl=$(IFS=','; echo "${pws[*]}")
    python3 - <<PYEOF 2>/dev/null
import json
with open('$CFG') as f: c = json.load(f)
c['auth']['config'] = [${pwl}]
with open('$CFG','w') as f: json.dump(c, f, indent=2)
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

# ════════════════════════════════════════════════════════════════
#  USER FUNCTIONS
# ════════════════════════════════════════════════════════════════
u_add() {
    show_header
    echo -e "  ${BLD}${W}── TAMBAH USER ─────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${C}Username${NC}: "; read -r un
    [[ -z "$un" ]] && { err "Username kosong!"; pause; return; }
    grep -q "^${un}|" "$UDB" 2>/dev/null && { err "Username sudah ada!"; pause; return; }

    echo -ne "  ${C}Password${NC} [auto]: "; read -r up
    [[ -z "$up" ]] && up=$(rand_pass)

    echo -ne "  ${C}Masa aktif (hari)${NC} [30]: "; read -r ud
    [[ -z "$ud" ]] && ud=30
    local ue; ue=$(date -d "+${ud} days" +"%Y-%m-%d")

    echo -ne "  ${C}Kuota GB (0=unlimited)${NC} [0]: "; read -r uq
    [[ -z "$uq" ]] && uq=0

    echo -ne "  ${C}Catatan/nama pembeli${NC} [-]: "; read -r note
    [[ -z "$note" ]] && note="-"

    echo "${un}|${up}|${ue}|${uq}|${note}" >> "$UDB"
    _reload_pw

    local domain; domain=$(get_domain)
    local port; port=$(get_port)
    local ql; [[ "$uq" == "0" ]] && ql="Unlimited" || ql="${uq} GB"

    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
    _tg_send "✅ <b>Akun Baru Dibuat</b>
👤 User    : <code>$un</code>
🔑 Pass    : <code>$up</code>
🌐 Host    : <code>$domain</code>
🔌 Port    : <code>$port</code>
📦 Kuota   : $ql
📅 Expired : $ue
📝 Catatan : $note"

    echo ""
    echo -e "  ${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${C}║${NC}  ${G}${BLD}✔  AKUN BERHASIL DIBUAT${NC}                               ${C}║${NC}"
    echo -e "  ${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${C}║${NC}  Username : ${W}$un${NC}"
    echo -e "  ${C}║${NC}  Password : ${W}$up${NC}"
    echo -e "  ${C}║${NC}  Host     : ${W}$domain${NC}"
    echo -e "  ${C}║${NC}  Port     : ${W}$port${NC}"
    echo -e "  ${C}║${NC}  Obfs     : ${W}zivpn${NC}"
    echo -e "  ${C}║${NC}  Kuota    : ${W}$ql${NC}"
    echo -e "  ${C}║${NC}  Expired  : ${W}$ue${NC}"
    echo -e "  ${C}║${NC}  Pembeli  : ${W}$note${NC}"
    echo -e "  ${C}╚══════════════════════════════════════════════════════════╝${NC}"
    pause
}

u_list() {
    show_header
    echo -e "  ${BLD}${W}── DAFTAR USER ─────────────────────────────────────────────${NC}"
    echo ""
    [[ ! -s "$UDB" ]] && { warn "Belum ada user."; pause; return; }
    local today; today=$(date +"%Y-%m-%d"); local n=1
    printf "  ${BLD}%-3s %-16s %-12s %-12s %-8s %-9s${NC}\n" "#" "Username" "Password" "Expired" "Kuota" "Status"
    hr
    while IFS='|' read -r u p e q _; do
        local sc sl; [[ "$e" < "$today" ]] && sc="$R" sl="EXPIRED" || sc="$G" sl="AKTIF"
        local ql; [[ "$q" == "0" ]] && ql="Unlim" || ql="${q}GB"
        printf "  %-3s ${W}%-16s${NC} %-12s ${Y}%-12s${NC} %-8s ${sc}%-9s${NC}\n" \
            "$n" "$u" "$p" "$e" "$ql" "$sl"
        ((n++))
    done < "$UDB"
    echo ""
    echo -e "  ${D}Total: $((n-1)) akun  |  Expired: $(exp_count)${NC}"
    pause
}

u_info() {
    show_header
    echo -e "  ${BLD}${W}── INFO AKUN ────────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${C}Username${NC}: "; read -r un
    local ln; ln=$(grep "^${un}|" "$UDB" 2>/dev/null)
    [[ -z "$ln" ]] && { err "User tidak ditemukan!"; pause; return; }
    IFS='|' read -r u p e q note <<< "$ln"
    local sisa=$(( ($(date -d "$e" +%s 2>/dev/null || echo 0) - $(date +%s)) / 86400 ))
    local domain; domain=$(get_domain); local port; port=$(get_port)
    local ql; [[ "$q" == "0" ]] && ql="Unlimited" || ql="${q} GB"
    local sc sl sisa_str
    if [[ $sisa -lt 0 ]]; then
        sc="$R"; sl="EXPIRED"; sisa_str="${R}Sudah expired${NC}"
    else
        sc="$G"; sl="AKTIF"; sisa_str="${G}${sisa} hari lagi${NC}"
    fi
    echo ""
    echo -e "  ${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${C}║${NC}  ${BLD}Detail Akun: ${W}$u${NC}"
    echo -e "  ${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${C}║${NC}  Username : ${W}$u${NC}"
    echo -e "  ${C}║${NC}  Password : ${W}$p${NC}"
    echo -e "  ${C}║${NC}  Host     : ${W}$domain${NC}"
    echo -e "  ${C}║${NC}  Port     : ${W}$port${NC}"
    echo -e "  ${C}║${NC}  Obfs     : ${W}zivpn${NC}"
    echo -e "  ${C}║${NC}  Kuota    : ${W}$ql${NC}"
    echo -e "  ${C}║${NC}  Expired  : ${W}$e${NC}"
    echo -e "  ${C}║${NC}  Sisa     : $sisa_str"
    echo -e "  ${C}║${NC}  Status   : ${sc}$sl${NC}"
    echo -e "  ${C}║${NC}  Pembeli  : ${W}$note${NC}"
    echo -e "  ${C}╚══════════════════════════════════════════════════════════╝${NC}"
    pause
}

u_del() {
    show_header
    echo -e "  ${BLD}${W}── HAPUS USER ──────────────────────────────────────────────${NC}"
    echo ""
    [[ ! -s "$UDB" ]] && { warn "Tidak ada user."; pause; return; }
    local n=1
    while IFS='|' read -r u _ e _ _; do
        echo -e "  ${n}. ${W}$u${NC}  ${D}(exp: $e)${NC}"; ((n++))
    done < "$UDB"
    echo ""
    echo -ne "  ${C}Username yang dihapus${NC}: "; read -r du
    grep -q "^${du}|" "$UDB" 2>/dev/null || { err "User tidak ditemukan!"; pause; return; }
    sed -i "/^${du}|/d" "$UDB"
    _reload_pw
    _tg_send "🗑 <b>Akun Dihapus</b>: <code>$du</code>"
    ok "User '${W}$du${NC}' berhasil dihapus."
    pause
}

u_renew() {
    show_header
    echo -e "  ${BLD}${W}── PERPANJANG USER ─────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${C}Username${NC}: "; read -r ru
    grep -q "^${ru}|" "$UDB" 2>/dev/null || { err "User tidak ditemukan!"; pause; return; }
    echo -ne "  ${C}Tambah hari${NC} [30]: "; read -r rd; [[ -z "$rd" ]] && rd=30
    local ce; ce=$(grep "^${ru}|" "$UDB" | cut -d'|' -f3)
    local today; today=$(date +%Y-%m-%d)
    [[ "$ce" < "$today" ]] && ce="$today"
    local ne; ne=$(date -d "${ce} +${rd} days" +"%Y-%m-%d")
    sed -i "s/^\(${ru}|[^|]*|\)[^|]*/\1${ne}/" "$UDB"
    _tg_send "🔄 <b>Perpanjang Akun</b>
👤 User    : <code>$ru</code>
📅 Expired : <b>$ne</b> (+${rd} hari)"
    ok "User '${W}$ru${NC}' diperpanjang → ${W}$ne${NC}"
    pause
}

u_chpass() {
    show_header
    echo -e "  ${BLD}${W}── GANTI PASSWORD ──────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${C}Username${NC}: "; read -r pu
    grep -q "^${pu}|" "$UDB" 2>/dev/null || { err "User tidak ditemukan!"; pause; return; }
    echo -ne "  ${C}Password baru${NC} [auto]: "; read -r pp
    [[ -z "$pp" ]] && pp=$(rand_pass)
    sed -i "s/^${pu}|[^|]*/${pu}|${pp}/" "$UDB"
    _reload_pw
    ok "Password '${W}$pu${NC}' diubah → ${W}$pp${NC}"
    pause
}

u_trial() {
    show_header
    echo -e "  ${BLD}${W}── BUAT AKUN TRIAL ─────────────────────────────────────────${NC}"
    echo ""
    local tu="trial$(tr -dc 'a-z0-9' </dev/urandom | head -c 5)"
    local tp; tp=$(rand_pass)
    local te; te=$(date -d "+1 day" +"%Y-%m-%d")
    echo "${tu}|${tp}|${te}|1|TRIAL" >> "$UDB"
    _reload_pw
    local domain; domain=$(get_domain); local port; port=$(get_port)
    _tg_send "🎁 <b>Akun Trial Dibuat</b>
👤 User  : <code>$tu</code>
🔑 Pass  : <code>$tp</code>
📅 Exp   : $te  (1 hari / 1 GB)"
    echo ""
    echo -e "  ${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${C}║${NC}  ${Y}${BLD}★  AKUN TRIAL 1 HARI / 1 GB ★${NC}                        ${C}║${NC}"
    echo -e "  ${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${C}║${NC}  Username : ${W}$tu${NC}"
    echo -e "  ${C}║${NC}  Password : ${W}$tp${NC}"
    echo -e "  ${C}║${NC}  Host     : ${W}$domain${NC}"
    echo -e "  ${C}║${NC}  Port     : ${W}$port${NC}"
    echo -e "  ${C}║${NC}  Obfs     : ${W}zivpn${NC}"
    echo -e "  ${C}║${NC}  Expired  : ${W}$te${NC}  (1 hari)"
    echo -e "  ${C}║${NC}  Kuota    : ${W}1 GB${NC}"
    echo -e "  ${C}╚══════════════════════════════════════════════════════════╝${NC}"
    pause
}

u_clean() {
    show_header
    echo -e "  ${BLD}${W}── HAPUS AKUN EXPIRED ──────────────────────────────────────${NC}"
    echo ""
    local today; today=$(date +%Y-%m-%d); local cnt=0
    while IFS='|' read -r u _ e _ _; do
        if [[ "$e" < "$today" ]]; then
            sed -i "/^${u}|/d" "$UDB"
            ok "Dihapus: ${W}$u${NC}  ${D}(exp: $e)${NC}"
            ((cnt++))
        fi
    done < <(cat "$UDB" 2>/dev/null)
    if [[ $cnt -gt 0 ]]; then
        _reload_pw
        ok "Total ${W}$cnt${NC} akun expired dihapus."
    else
        inf "Tidak ada akun expired."
    fi
    pause
}

# ════════════════════════════════════════════════════════════════
#  JUALAN
# ════════════════════════════════════════════════════════════════
t_akun() {
    show_header
    echo -e "  ${BLD}${W}── TEMPLATE PESAN AKUN ─────────────────────────────────────${NC}"
    echo ""
    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
    echo -ne "  ${C}Username${NC}: "; read -r tu
    local ln; ln=$(grep "^${tu}|" "$UDB" 2>/dev/null)
    [[ -z "$ln" ]] && { err "User tidak ditemukan!"; pause; return; }
    IFS='|' read -r u p e q note <<< "$ln"
    local domain; domain=$(get_domain); local port; port=$(get_port)
    local ql; [[ "$q" == "0" ]] && ql="Unlimited" || ql="${q} GB"
    echo ""
    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}🔒 ${BRAND:-OGH-ZIV} — AKUN UDP VPN${NC}"
    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "📌 Detail Akun"
    echo -e "├─ Username : ${W}$u${NC}"
    echo -e "├─ Password : ${W}$p${NC}"
    echo -e "├─ Host     : ${W}$domain${NC}"
    echo -e "├─ Port     : ${W}$port${NC}"
    echo -e "├─ Obfs     : ${W}zivpn${NC}"
    echo -e "├─ Kuota    : ${W}$ql${NC}"
    echo -e "└─ Expired  : ${W}$e${NC}"
    echo -e ""
    echo -e "📱 Cara Pakai"
    echo -e "1. Download ZiVPN di Play Store / App Store"
    echo -e "2. Buka → Add Server → isi data di atas"
    echo -e "3. Tap Connect — selesai!"
    echo -e ""
    [[ "$ADMIN_TG" != "-" && -n "$ADMIN_TG" ]] && echo -e "📨 Support : ${C}t.me/${ADMIN_TG}${NC}"
    echo -e ""
    echo -e "⚠️  Dilarang share akun ke orang lain"
    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    pause
}

set_store() {
    show_header
    echo -e "  ${BLD}${W}── PENGATURAN TOKO ──────────────────────────────────────────${NC}"
    echo ""
    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
    echo -ne "  ${C}Nama Brand${NC} [${BRAND:-OGH-ZIV}]: "; read -r ib
    echo -ne "  ${C}Username Telegram Admin${NC} [${ADMIN_TG:--}]: "; read -r it
    local nb="${ib:-${BRAND:-OGH-ZIV}}"
    local nt="${it:-${ADMIN_TG:--}}"
    cat > "$STRF" <<STEOF2
BRAND=$nb
ADMIN_TG=$nt
STEOF2
    ok "Pengaturan toko disimpan!"
    pause
}

# ════════════════════════════════════════════════════════════════
#  TELEGRAM BOT
# ════════════════════════════════════════════════════════════════
tg_setup() {
    show_header
    echo -e "  ${BLD}${W}── SETUP BOT TELEGRAM ───────────────────────────────────────${NC}"
    echo ""
    inf "Cara mendapat token → buka ${C}@BotFather${NC} di Telegram → /newbot"
    inf "Cara mendapat Chat ID → kirim /start ke bot, lalu buka URL:"
    echo -e "  ${D}https://api.telegram.org/bot<TOKEN>/getUpdates${NC}"
    echo ""
    echo -ne "  ${C}Bot Token${NC}: "; read -r tok
    [[ -z "$tok" ]] && { err "Token kosong!"; pause; return; }
    echo -ne "  ${C}Chat ID Admin${NC}: "; read -r cid
    [[ -z "$cid" ]] && { err "Chat ID kosong!"; pause; return; }

    local res; res=$(curl -s "https://api.telegram.org/bot${tok}/getMe")
    if echo "$res" | grep -q '"ok":true'; then
        local bname; bname=$(echo "$res" | python3 -c \
            "import sys,json;d=json.load(sys.stdin);print(d['result']['username'])" 2>/dev/null)
        cat > "$BOTF" <<BEOF
BOT_TOKEN=$tok
CHAT_ID=$cid
BOT_NAME=$bname
BEOF
        curl -s -X POST "https://api.telegram.org/bot${tok}/sendMessage" \
            -d "chat_id=${cid}" -d "text=✅ OGH-ZIV bot terhubung ke server!" &>/dev/null
        ok "Bot terhubung → ${W}@${bname}${NC}"
        ok "Pesan test dikirim ke Telegram!"
    else
        err "Token tidak valid atau tidak bisa terhubung!"
    fi
    pause
}

tg_status() {
    show_header
    echo -e "  ${BLD}${W}── STATUS BOT TELEGRAM ──────────────────────────────────────${NC}"
    echo ""
    if [[ ! -f "$BOTF" ]]; then
        warn "Bot belum dikonfigurasi."
        echo -ne "  Setup sekarang? [y/N]: "; read -r a
        [[ "$a" == [yY] ]] && tg_setup
        return
    fi
    source "$BOTF" 2>/dev/null
    local res; res=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")
    if echo "$res" | grep -q '"ok":true'; then
        local fname; fname=$(echo "$res" | python3 -c \
            "import sys,json;d=json.load(sys.stdin);print(d['result']['first_name'])" 2>/dev/null)
        ok "Bot aktif : ${W}$fname${NC}  (@${BOT_NAME})"
        ok "Chat ID   : ${W}$CHAT_ID${NC}"
        echo ""
        echo -ne "  ${C}Kirim pesan test?${NC} [y/N]: "; read -r ts
        [[ "$ts" == [yY] ]] && {
            curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                -d "chat_id=${CHAT_ID}" \
                -d "text=🟢 Test dari OGH-ZIV — Bot aktif!" &>/dev/null
            ok "Pesan test dikirim!"
        }
    else
        err "Bot tidak dapat terhubung. Cek token!"
    fi
    pause
}

tg_kirim_akun() {
    show_header
    echo -e "  ${BLD}${W}── KIRIM AKUN KE TELEGRAM ───────────────────────────────────${NC}"
    echo ""
    [[ ! -f "$BOTF" ]] && { err "Bot belum dikonfigurasi!"; pause; return; }
    source "$BOTF" 2>/dev/null
    [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null

    echo -ne "  ${C}Username akun${NC}: "; read -r su
    local ln; ln=$(grep "^${su}|" "$UDB" 2>/dev/null)
    [[ -z "$ln" ]] && { err "User tidak ditemukan!"; pause; return; }
    IFS='|' read -r u p e q note <<< "$ln"

    echo -ne "  ${C}Chat ID tujuan${NC} [$CHAT_ID]: "; read -r did
    [[ -z "$did" ]] && did="$CHAT_ID"

    local domain; domain=$(get_domain); local port; port=$(get_port)
    local ql; [[ "$q" == "0" ]] && ql="Unlimited" || ql="${q} GB"

    local msg="🔒 <b>${BRAND:-OGH-ZIV} — Akun VPN UDP</b>

📌 <b>Detail Akun</b>
├ Username : <code>$u</code>
├ Password : <code>$p</code>
├ Host     : <code>$domain</code>
├ Port     : <code>$port</code>
├ Obfs     : <code>zivpn</code>
├ Kuota    : <b>$ql</b>
└ Expired  : <b>$e</b>

📱 Download ZiVPN di Play Store / App Store
⚠️ Jangan share akun ini!"

    local r; r=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${did}" -d "text=${msg}" -d "parse_mode=HTML")
    echo "$r" | grep -q '"ok":true' \
        && ok "Akun '${W}$u${NC}' berhasil dikirim ke Telegram!" \
        || err "Gagal kirim! Cek Chat ID atau token."
    pause
}

tg_broadcast() {
    show_header
    echo -e "  ${BLD}${W}── BROADCAST PESAN ──────────────────────────────────────────${NC}"
    echo ""
    [[ ! -f "$BOTF" ]] && { err "Bot belum dikonfigurasi!"; pause; return; }
    source "$BOTF" 2>/dev/null
    echo -e "  ${C}Ketik pesan (ketik ${W}SELESAI${C} di baris baru untuk kirim):${NC}"
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
    echo -e "  ${BLD}${W}── PANDUAN MEMBUAT BOT TELEGRAM ──────────────────────────────${NC}"
    echo ""
    echo -e "  ${Y}┌─ LANGKAH 1: Buat Bot ───────────────────────────────────┐${NC}"
    echo -e "  ${Y}│${NC}  ${W}1.${NC} Buka Telegram → cari ${C}@BotFather${NC}"
    echo -e "  ${Y}│${NC}  ${W}2.${NC} Kirim perintah: ${C}/newbot${NC}"
    echo -e "  ${Y}│${NC}  ${W}3.${NC} Masukkan nama bot, contoh: ${C}OGH ZIV VPN${NC}"
    echo -e "  ${Y}│${NC}  ${W}4.${NC} Masukkan username (harus akhiran 'bot')"
    echo -e "  ${Y}│${NC}     Contoh: ${C}oghziv_vpn_bot${NC}"
    echo -e "  ${Y}│${NC}  ${W}5.${NC} Salin ${Y}TOKEN${NC} yang diberikan — simpan baik-baik!"
    echo -e "  ${Y}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${C}┌─ LANGKAH 2: Ambil Chat ID ─────────────────────────────┐${NC}"
    echo -e "  ${C}│${NC}  ${W}1.${NC} Kirim /start ke bot kamu di Telegram"
    echo -e "  ${C}│${NC}  ${W}2.${NC} Buka URL ini di browser:"
    echo -e "  ${C}│${NC}     ${D}https://api.telegram.org/bot<TOKEN>/getUpdates${NC}"
    echo -e "  ${C}│${NC}  ${W}3.${NC} Cari ${Y}\"id\"${NC} di dalam bagian ${Y}\"from\"${NC}"
    echo -e "  ${C}│${NC}  ${W}4.${NC} Angka tersebut adalah ${Y}Chat ID${NC} kamu"
    echo -e "  ${C}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${G}┌─ LANGKAH 3: Hubungkan ke OGH-ZIV ─────────────────────┐${NC}"
    echo -e "  ${G}│${NC}  ${W}1.${NC} Buka menu ${C}Telegram Bot${NC} di script ini"
    echo -e "  ${G}│${NC}  ${W}2.${NC} Pilih ${C}[1] Setup / Konfigurasi Bot${NC}"
    echo -e "  ${G}│${NC}  ${W}3.${NC} Masukkan Token dan Chat ID"
    echo -e "  ${G}│${NC}  ${W}4.${NC} Selesai! Notifikasi otomatis aktif ✅"
    echo -e "  ${G}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${BLD}Link BotFather:${NC} ${W}https://t.me/BotFather${NC}"
    echo ""
    echo -e "  ${Y}Tips perintah di BotFather:${NC}"
    echo -e "  ${D}/setdescription${NC}  — ubah deskripsi bot"
    echo -e "  ${D}/setuserpic${NC}      — pasang foto profil bot"
    echo -e "  ${D}/setcommands${NC}     — atur daftar perintah"
    echo -e "  ${D}/mybots${NC}          — lihat semua bot milikmu"
    pause
}

# ════════════════════════════════════════════════════════════════
#  SERVICE
# ════════════════════════════════════════════════════════════════
svc_status() {
    show_header
    echo -e "  ${BLD}${W}── STATUS SERVICE ───────────────────────────────────────────${NC}"
    echo ""
    systemctl status zivpn --no-pager -l
    pause
}

svc_log() {
    show_header
    echo -e "  ${BLD}${W}── LOG ZIVPN ─────────────────────────────────────────────────${NC}"
    echo ""
    [[ -f "$LOG" ]] && tail -60 "$LOG" || journalctl -u zivpn -n 60 --no-pager
    pause
}

svc_port() {
    show_header
    echo -e "  ${BLD}${W}── GANTI PORT ────────────────────────────────────────────────${NC}"
    echo ""
    local cp; cp=$(get_port)
    echo -e "  Port saat ini: ${W}$cp${NC}"
    echo -ne "  ${C}Port baru${NC}: "; read -r np
    [[ ! "$np" =~ ^[0-9]+$ || $np -lt 1 || $np -gt 65535 ]] && { err "Port tidak valid!"; pause; return; }
    sed -i "s/\"listen\": *\":${cp}\"/\"listen\": \":${np}\"/" "$CFG"
    command -v ufw &>/dev/null && {
        ufw delete allow "$cp/udp" &>/dev/null
        ufw allow "$np/udp" &>/dev/null
    }
    iptables -D INPUT -p udp --dport "$cp" -j ACCEPT 2>/dev/null
    iptables -I INPUT -p udp --dport "$np" -j ACCEPT 2>/dev/null
    systemctl restart zivpn
    ok "Port diubah: ${W}$cp${NC} → ${W}$np${NC}"
    pause
}

# ════════════════════════════════════════════════════════════════
#  UNINSTALL
# ════════════════════════════════════════════════════════════════
do_uninstall() {
    show_header
    echo -e "  ${BLD}${R}── UNINSTALL ─────────────────────────────────────────────────${NC}"
    echo ""
    warn "Semua data user & konfigurasi akan DIHAPUS PERMANEN!"
    echo -ne "  ${R}Ketik 'HAPUS' untuk konfirmasi${NC}: "; read -r cf
    [[ "$cf" != "HAPUS" ]] && { inf "Dibatalkan."; pause; return; }
    systemctl stop zivpn 2>/dev/null
    systemctl disable zivpn 2>/dev/null
    rm -f "$SVC" "$BIN"
    rm -rf "$DIR"
    systemctl daemon-reload
    ok "OGH-ZIV berhasil diuninstall."
    pause
}

# ════════════════════════════════════════════════════════════════
#  SUB MENUS
# ════════════════════════════════════════════════════════════════
menu_user() {
    while true; do
        show_header
        echo -e "  ${BLD}${W}── MANAJEMEN USER ───────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${G}[1]${NC}  Tambah User Baru"
        echo -e "  ${G}[2]${NC}  Lihat Daftar User"
        echo -e "  ${G}[3]${NC}  Info Detail User"
        echo -e "  ${G}[4]${NC}  Hapus User"
        echo -e "  ${G}[5]${NC}  Perpanjang User"
        echo -e "  ${G}[6]${NC}  Ganti Password"
        echo -e "  ${Y}[7]${NC}  Buat Akun Trial  ${D}(1 hari / 1 GB)${NC}"
        echo -e "  ${Y}[8]${NC}  Hapus Semua Akun Expired"
        echo -e "  ${R}[0]${NC}  Kembali"
        echo ""
        echo -ne "  ${C}›${NC} "; read -r ch
        case $ch in
            1) u_add ;; 2) u_list ;; 3) u_info ;;
            4) u_del ;; 5) u_renew ;; 6) u_chpass ;;
            7) u_trial ;; 8) u_clean ;;
            0) break ;; *) warn "Tidak valid"; sleep 1 ;;
        esac
    done
}

menu_jualan() {
    while true; do
        show_header
        [[ -f "$STRF" ]] && source "$STRF" 2>/dev/null
        echo -e "  ${BLD}${W}── MENU JUALAN ───────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${G}[1]${NC}  Template Pesan Akun  ${D}(tampil di terminal)${NC}"
        echo -e "  ${G}[2]${NC}  Kirim Akun via Telegram"
        echo -e "  ${Y}[3]${NC}  Pengaturan Toko  ${D}(brand · TG admin)${NC}"
        echo -e "  ${R}[0]${NC}  Kembali"
        echo ""
        echo -e "  ${D}Brand: ${BRAND:-OGH-ZIV}  |  TG: @${ADMIN_TG:--}${NC}"
        echo ""
        echo -ne "  ${C}›${NC} "; read -r ch
        case $ch in
            1) t_akun ;; 2) tg_kirim_akun ;; 3) set_store ;;
            0) break ;; *) warn "Tidak valid"; sleep 1 ;;
        esac
    done
}

menu_telegram() {
    while true; do
        show_header
        local bstat="${R}Belum dikonfigurasi${NC}"
        if [[ -f "$BOTF" ]]; then
            source "$BOTF" 2>/dev/null
            bstat="${G}@${BOT_NAME}${NC}"
        fi
        echo -e "  ${BLD}${W}── TELEGRAM BOT ──────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${D}Status Bot :${NC} $bstat"
        echo ""
        echo -e "  ${G}[1]${NC}  Setup / Konfigurasi Bot"
        echo -e "  ${G}[2]${NC}  Cek Status Bot"
        echo -e "  ${G}[3]${NC}  Kirim Akun ke Telegram"
        echo -e "  ${G}[4]${NC}  Broadcast Pesan ke Admin"
        echo -e "  ${Y}[5]${NC}  Panduan Membuat Bot Telegram"
        echo -e "  ${R}[0]${NC}  Kembali"
        echo ""
        echo -ne "  ${C}›${NC} "; read -r ch
        case $ch in
            1) tg_setup ;; 2) tg_status ;; 3) tg_kirim_akun ;;
            4) tg_broadcast ;; 5) tg_guide ;;
            0) break ;; *) warn "Tidak valid"; sleep 1 ;;
        esac
    done
}

menu_service() {
    while true; do
        show_header
        echo -e "  ${BLD}${W}── MANAJEMEN SERVICE ────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${G}[1]${NC}  Status Service"
        echo -e "  ${G}[2]${NC}  Start ZiVPN"
        echo -e "  ${G}[3]${NC}  Stop ZiVPN"
        echo -e "  ${G}[4]${NC}  Restart ZiVPN"
        echo -e "  ${G}[5]${NC}  Lihat Log"
        echo -e "  ${Y}[6]${NC}  Ganti Port"
        echo -e "  ${R}[0]${NC}  Kembali"
        echo ""
        echo -ne "  ${C}›${NC} "; read -r ch
        case $ch in
            1) svc_status ;;
            2) systemctl start zivpn; ok "ZiVPN dijalankan."; pause ;;
            3) systemctl stop zivpn; ok "ZiVPN dihentikan."; pause ;;
            4) systemctl restart zivpn; sleep 1
               is_up && ok "Restart berhasil!" || err "Gagal restart!"; pause ;;
            5) svc_log ;; 6) svc_port ;;
            0) break ;; *) warn "Tidak valid"; sleep 1 ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════
#  MENU UTAMA
# ════════════════════════════════════════════════════════════════
main_menu() {
    while true; do
        show_header
        echo -e "  ${BLD}${W}── MENU UTAMA ────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${G}[1]${NC}  ${BLD}Install ZiVPN${NC}          ${D}← mulai di sini${NC}"
        echo -e "  ${G}[2]${NC}  Manajemen User         ${D}tambah · hapus · perpanjang${NC}"
        echo -e "  ${G}[3]${NC}  Menu Jualan            ${D}template · kirim akun${NC}"
        echo -e "  ${C}[4]${NC}  Telegram Bot           ${D}setup · kirim · broadcast${NC}"
        echo -e "  ${C}[5]${NC}  Manajemen Service      ${D}start · stop · log · port${NC}"
        echo -e "  ${Y}[6]${NC}  Refresh"
        echo -e "  ${R}[7]${NC}  Uninstall ZiVPN"
        echo -e "  ${R}[0]${NC}  Keluar"
        echo ""
        echo -ne "  ${C}›${NC} "
        read -r ch
        case $ch in
            1) do_install ;;
            2) menu_user ;;
            3) menu_jualan ;;
            4) menu_telegram ;;
            5) menu_service ;;
            6) : ;;
            7) do_uninstall ;;
            0) echo -e "\n  ${G}Sampai jumpa!${NC}\n"; exit 0 ;;
            *) warn "Tidak valid"; sleep 1 ;;
        esac
    done
}

check_root
main_menu
