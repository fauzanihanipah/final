
<div align="center">

```
    ╱╱  ██████╗  ██████╗ ██╗  ██╗  ╱╱
   ╱╱  ██╔═══██╗██╔════╝ ██║  ██║  ╱╱
  ╱╱   ██║   ██║██║  ███╗███████║  ╱╱
 ╱╱    ██║   ██║██║   ██║██╔══██║  ╱╱
╱╱     ╚██████╔╝╚██████╔╝██║  ██║  ╱╱

      ╱╱  ███████╗██╗██╗   ██╗  ╱╱
     ╱╱  ╚══███╔╝██║██║   ██║  ╱╱
    ╱╱     ███╔╝ ██║██║   ██║  ╱╱
   ╱╱     ███╔╝  ██║╚██╗ ██╔╝  ╱╱
  ╱╱     ███████╗██║ ╚████╔╝   ╱╱
```

### ✦ PREMIUM ZIVPN PANEL ✦

[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![UDP](https://img.shields.io/badge/Protocol-UDP-9B59B6?style=for-the-badge&logo=cloudflare&logoColor=white)](https://github.com/fauzanihanipah/ziv-udp)
[![Telegram](https://img.shields.io/badge/Bot-Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://core.telegram.org/bots)

*Script manajemen VPN UDP premium — install otomatis, kelola akun, jualan, dan notifikasi Telegram.*

---

</div>

## ✨ Fitur

| | Fitur | Keterangan |
|---|---|---|
| 🚀 | **Auto Install** | Download binary, SSL, config, systemd — satu perintah |
| 👥 | **Manajemen User** | Tambah, hapus, perpanjang, ganti password, trial 1 hari |
| 🎨 | **Bingkai Akun** | Detail akun tampil dalam kotak premium siap kirim ke pelanggan |
| 🛒 | **Menu Jualan** | Template pesan + kirim langsung via bot Telegram |
| 🤖 | **Telegram Bot** | Notifikasi otomatis setiap aksi + kirim akun ke pelanggan |
| 📊 | **Info VPS Real-time** | CPU, RAM, disk, uptime, status service — tampil di setiap menu |
| 💾 | **Backup & Restore** | Simpan & pulihkan seluruh data user kapan saja |
| 📊 | **Bandwidth Monitor** | Lihat koneksi UDP aktif & statistik network |
| 🔒 | **SSL Otomatis** | Sertifikat self-signed EC 10 tahun auto-generate |

---

## ⚡ Instalasi di VPS

> **Satu perintah langsung jalan:**

```bash
wget -O ogh-ziv.sh https://github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh && chmod +x ogh-ziv.sh && bash ogh-ziv.sh
```

> Atau dengan `curl`:

```bash
curl -sL https://github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh -o ogh-ziv.sh && chmod +x ogh-ziv.sh && bash ogh-ziv.sh
```

> Buka menu kapan saja setelah install:

```bash
bash ogh-ziv.sh
```

---

## 📋 Persyaratan VPS

| Spesifikasi | Minimum |
|---|---|
| **OS** | Ubuntu 18.04+ · Debian 9+ · CentOS 7+ |
| **RAM** | 256 MB |
| **Disk** | 1 GB |
| **Akses** | Root |
| **Internet** | Aktif saat instalasi |

---

## 🛠️ Instalasi Manual Langkah per Langkah

### 1 — Login sebagai root

```bash
sudo -i
```

### 2 — Download script

```bash
wget -O ogh-ziv.sh https://github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh
```

### 3 — Beri izin eksekusi

```bash
chmod +x ogh-ziv.sh
```

### 4 — Jalankan

```bash
bash ogh-ziv.sh
```

### 5 — Pilih **\[D\] Install ZiVPN** dan ikuti prompt

```
Domain / IP            :  (tekan Enter untuk IP otomatis)
Port [5667]            :  (tekan Enter untuk default)
Nama Brand / Toko      :  OGH-ZIV
Username Telegram Admin:  (opsional)
```

---

## 📂 Struktur File Setelah Install

```
/etc/zivpn/
├── config.json      ← konfigurasi ZiVPN (port, obfs, auth)
├── zivpn.crt        ← sertifikat SSL (10 tahun)
├── zivpn.key        ← private key SSL
├── users.db         ← database semua akun
├── bot.conf         ← token & chat ID bot Telegram
├── store.conf       ← nama brand & admin Telegram
├── domain.conf      ← domain atau IP server
└── zivpn.log        ← log service

/usr/local/bin/zivpn               ← binary ZiVPN
/etc/systemd/system/zivpn.service  ← systemd service
```

---

## 📖 Panduan Menu Lengkap

### Menu Utama

```
╔══════════════════════════════════════════════════════╗
║  ✦ PREMIUM ZIVPN PANEL  ✦                           ║
║  Pilih menu di bawah 👇                             ║
╠═══════════════════════╦══════════════════════════════╣
║  📋 [1] List Akun     ║  🖥️ [2] Status VPS          ║
╠═══════════════════════╬══════════════════════════════╣
║  📊 [3] Bandwidth     ║  💾 [4] Backup              ║
╠═══════════════════════╩══════════════════════════════╣
║  ♻️  [5] Restore                                     ║
╠══════════════════════════════════════════════════════╣
║  🔄 [6] Restart Service                             ║
╠═══════════════════════╦══════════════════════════════╣
║  ➕ [7] Add User      ║  🗑️ [8] Del User            ║
╠═══════════════════════╩══════════════════════════════╣
║  🔁 [9] Perpanjang Akun                             ║
╠══════════════════════════════════════════════════════╣
║  🛒 [A] Menu Jualan                                 ║
╠══════════════════════════════════════════════════════╣
║  🤖 [B] Telegram Bot                               ║
╠══════════════════════════════════════════════════════╣
║  ⚙️  [C] Manajemen Service                          ║
╠══════════════════════════════════════════════════════╣
║  🚀 [D] Install ZiVPN                              ║
╠══════════════════════════════════════════════════════╣
║  🗑️  [E] Uninstall ZiVPN                            ║
╠══════════════════════════════════════════════════════╣
║  ◀  [0] Keluar                                     ║
╚══════════════════════════════════════════════════════╝
```

---

### 👥 Manajemen User

| Pilihan | Fungsi |
|---|---|
| `[1]` List Akun | Tabel semua akun + status aktif/expired |
| `[7]` Add User | Buat akun baru, notif Telegram otomatis |
| `[8]` Del User | Hapus akun, config auto-update |
| `[9]` Perpanjang | Tambah masa aktif dari tanggal expired |
| `[A]` Ganti Password | Ubah password + restart service otomatis |
| `[B]` Trial Akun | Akun 1 hari / 1 GB, username random |
| `[C]` Hapus Expired | Bersihkan semua akun yang sudah kedaluwarsa |
| `[D]` Info Akun | Detail lengkap 1 akun dalam bingkai premium |

### 🛒 Menu Jualan

| Pilihan | Fungsi |
|---|---|
| `[1]` Template Pesan | Tampilkan detail akun dalam bingkai siap kirim |
| `[2]` Kirim via Telegram | Kirim detail akun langsung ke chat pelanggan |
| `[3]` Pengaturan Toko | Ubah nama brand & username Telegram admin |

### 🤖 Telegram Bot

| Pilihan | Fungsi |
|---|---|
| `[1]` Setup Bot | Masukkan token & chat ID, test koneksi |
| `[2]` Status Bot | Cek apakah bot aktif & terhubung |
| `[3]` Kirim Akun | Kirim detail akun ke chat ID tertentu |
| `[4]` Broadcast | Kirim pesan bebas ke admin |
| `[5]` Panduan | Tutorial step-by-step buat bot dari nol |

### ⚙️ Manajemen Service

| Pilihan | Fungsi |
|---|---|
| `[1]` Status | Lihat status systemd ZiVPN |
| `[2]` Start | Jalankan service |
| `[3]` Stop | Hentikan service |
| `[4]` Restart | Restart service |
| `[5]` Log | Lihat 60 baris log terakhir |
| `[6]` Ganti Port | Ubah port + update firewall otomatis |
| `[7]` Backup | Simpan seluruh data ke file .tar.gz |
| `[8]` Restore | Pulihkan data dari file backup |

---

## 🎨 Tampilan Bingkai Akun

Setiap kali akun dibuat, bingkai berikut otomatis tampil:

```
╔══════════════════════════════════════════════════════════╗
║  ✦ OGH-ZIV — AKUN UDP VPN PREMIUM                      ║
╠══════════════╦═══════════════════════════════════════════╣
║  Username    ║  john123                                 ║
║  Password    ║  aB3xKq9mNp                              ║
╠══════════════╬═══════════════════════════════════════════╣
║  Host        ║  103.xx.xx.xx                            ║
║  Port        ║  5667                                    ║
║  Obfs        ║  zivpn                                   ║
╠══════════════╬═══════════════════════════════════════════╣
║  Kuota       ║  Unlimited                               ║
║  Expired     ║  2026-04-05                              ║
║  Sisa        ║  30 hari lagi                            ║
║  Pembeli     ║  Budi                                    ║
╠══════════════╩═══════════════════════════════════════════╣
║  📱 Download ZiVPN → Play Store / App Store             ║
║  ⚠  Jangan share akun ini ke orang lain!               ║
╚══════════════════════════════════════════════════════════╝
```

---

## 🤖 Setup Bot Telegram

### Langkah 1 — Buat Bot

```
1. Buka Telegram → cari @BotFather
2. Ketik /newbot
3. Masukkan nama bot  →  contoh: OGH ZIV VPN
4. Masukkan username  →  contoh: oghziv_vpn_bot
5. Salin TOKEN yang diberikan
```

### Langkah 2 — Dapatkan Chat ID

```
1. Kirim /start ke bot kamu
2. Buka di browser:
   https://api.telegram.org/bot<TOKEN>/getUpdates
3. Temukan "id" di bagian "from" → itulah Chat ID
```

### Langkah 3 — Hubungkan ke OGH-ZIV

```
Menu Utama → [B] Telegram Bot → [1] Setup Bot
→ Masukkan Token
→ Masukkan Chat ID
→ ✅ Selesai!
```

**Notifikasi otomatis aktif untuk:**
- ✅ Akun baru dibuat
- 🔁 Akun diperpanjang
- 🗑️ Akun dihapus
- 🎁 Akun trial dibuat

---

## 🔧 Perintah Cepat

```bash
# Buka menu OGH-ZIV
bash ogh-ziv.sh

# Cek status service
systemctl status zivpn

# Restart service
systemctl restart zivpn

# Log real-time
journalctl -u zivpn -f

# Lihat semua akun
cat /etc/zivpn/users.db

# Cek port aktif
ss -tulpn | grep zivpn

# Lihat log file
tail -f /etc/zivpn/zivpn.log

# Backup manual
tar -czf backup-zivpn.tar.gz /etc/zivpn
```

---

## ❓ Troubleshooting

**Service tidak bisa start**
```bash
journalctl -u zivpn -n 50 --no-pager
# Pastikan port tidak dipakai proses lain
ss -tulpn | grep 5667
```

**Binary gagal didownload**
```bash
wget -O /usr/local/bin/zivpn \
  https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64
chmod +x /usr/local/bin/zivpn
```

**Bot Telegram tidak bisa kirim**
```bash
# Cek konfigurasi bot
cat /etc/zivpn/bot.conf
# Pastikan sudah /start ke bot terlebih dahulu
```

**Akun tidak bisa konek dari aplikasi**
```bash
# Cek port terbuka
iptables -L INPUT -n | grep 5667
# Buka port manual
iptables -I INPUT -p udp --dport 5667 -j ACCEPT
```

---

## 🗑️ Uninstall

Di dalam menu pilih `[E] Uninstall ZiVPN`, ketik `HAPUS` untuk konfirmasi.

Atau manual:

```bash
systemctl stop zivpn && systemctl disable zivpn
rm -f /etc/systemd/system/zivpn.service /usr/local/bin/zivpn
rm -rf /etc/zivpn
systemctl daemon-reload
```

---

## 📦 Sumber

| Komponen | URL |
|---|---|
| **Script** | `github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh` |
| **Binary** | `github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64` |
| **Config** | `github.com/fauzanihanipah/ziv-udp/raw/main/config.json` |

---

<div align="center">

**OGH-ZIV Premium** — dibuat dengan ❤️

*Install sekali, kelola selamanya.*

</div>
