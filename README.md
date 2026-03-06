<div align="center">

```
  ██████╗  ██████╗ ██╗  ██╗    ███████╗██╗██╗   ██╗
 ██╔═══██╗██╔════╝ ██║  ██║    ╚══███╔╝██║██║   ██║
 ██║   ██║██║  ███╗███████║      ███╔╝ ██║██║   ██║
 ██║   ██║██║   ██║██╔══██║     ███╔╝  ██║╚██╗ ██╔╝
 ╚██████╔╝╚██████╔╝██║  ██║    ███████╗██║ ╚████╔╝
  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝    ╚══════╝╚═╝  ╚═══╝
```

**UDP VPN Manager & Selling System**

[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![ZiVPN](https://img.shields.io/badge/Engine-ZiVPN_UDP-00B4D8?style=for-the-badge&logo=shield&logoColor=white)](https://github.com/fauzanihanipah/ziv-udp)
[![Telegram](https://img.shields.io/badge/Bot-Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://core.telegram.org/bots)

*Script manajemen VPN UDP lengkap — install, kelola akun, jualan, dan notifikasi Telegram otomatis.*

---

</div>

## ✨ Fitur Unggulan

| Fitur | Keterangan |
|-------|------------|
| 🚀 **Auto Install** | Download binary, generate SSL, setup systemd otomatis |
| 👥 **Manajemen User** | Tambah, hapus, perpanjang, ganti password, trial |
| 🛒 **Menu Jualan** | Template pesan akun siap kirim ke pelanggan |
| 🤖 **Bot Telegram** | Notifikasi & kirim akun langsung via Telegram |
| 📊 **Info VPS Real-time** | CPU, RAM, disk, status service tampil di menu |
| 🔒 **SSL Otomatis** | Sertifikat self-signed 10 tahun auto-generate |
| 🔁 **Auto Restart** | Service otomatis restart jika crash |

---

## ⚡ Instalasi Cepat

> **Satu perintah langsung jalan:**

```bash
wget -O ogh-ziv.sh https://github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh && chmod +x ogh-ziv.sh && bash ogh-ziv.sh
```

atau pakai `curl`:

```bash
curl -sL https://github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh -o ogh-ziv.sh && chmod +x ogh-ziv.sh && bash ogh-ziv.sh
```

---

## 📋 Persyaratan VPS

| Spesifikasi | Minimum |
|-------------|---------|
| **OS** | Ubuntu 18.04 / 20.04 / 22.04 · Debian 9+ · CentOS 7+ |
| **RAM** | 256 MB |
| **Disk** | 1 GB |
| **Akses** | Root / sudo |
| **Koneksi** | Internet aktif |

---

## 🛠️ Langkah-Langkah Instalasi Manual

### 1 — Login ke VPS sebagai root

```bash
sudo -i
# atau
sudo su -
```

### 2 — Download script

```bash
wget -O ogh-ziv.sh https://github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh
```

### 3 — Beri izin eksekusi

```bash
chmod +x ogh-ziv.sh
```

### 4 — Jalankan script

```bash
bash ogh-ziv.sh
```

### 5 — Di dalam menu, pilih **[1] Install ZiVPN**

```
  ── MENU UTAMA ────────────────────────────────────────────────
  [1]  Install ZiVPN          ← mulai di sini
  [2]  Manajemen User
  [3]  Menu Jualan
  [4]  Telegram Bot
  [5]  Manajemen Service
  ...
```

Ikuti prompt:
- Masukkan **domain / IP VPS**
- Masukkan **port** (default: `5667`)
- Masukkan **nama brand toko**
- Masukkan **username Telegram admin** (opsional)

---

## 📂 Struktur File

Setelah install, semua file tersimpan di:

```
/etc/zivpn/
├── config.json      ← konfigurasi ZiVPN
├── zivpn.crt        ← sertifikat SSL
├── zivpn.key        ← private key SSL
├── users.db         ← database akun
├── bot.conf         ← konfigurasi bot Telegram
├── store.conf       ← konfigurasi brand toko
├── domain.conf      ← domain / IP server
└── zivpn.log        ← log service

/usr/local/bin/zivpn           ← binary ZiVPN
/etc/systemd/system/zivpn.service  ← systemd service
```

---

## 📖 Panduan Menu

### 👥 Manajemen User

```
[1]  Tambah User Baru       → input username, password, masa aktif, kuota
[2]  Lihat Daftar User      → tabel semua akun + status aktif/expired
[3]  Info Detail User       → detail lengkap 1 akun termasuk sisa hari
[4]  Hapus User             → hapus akun & update config otomatis
[5]  Perpanjang User        → tambah hari dari tanggal expired
[6]  Ganti Password         → ubah password, restart service otomatis
[7]  Buat Akun Trial        → akun 1 hari / 1 GB, username random
[8]  Hapus Akun Expired     → bersihkan semua akun yang sudah expired
```

### 🛒 Menu Jualan

```
[1]  Template Pesan Akun    → tampilkan detail akun format siap kirim ke pelanggan
[2]  Kirim Akun via Telegram → kirim detail akun langsung ke chat Telegram
[3]  Pengaturan Toko        → ubah nama brand & username Telegram admin
```

### 🤖 Telegram Bot

```
[1]  Setup / Konfigurasi Bot  → masukkan token & chat ID
[2]  Cek Status Bot           → verifikasi koneksi bot
[3]  Kirim Akun ke Telegram   → kirim detail akun ke chat ID tertentu
[4]  Broadcast Pesan          → kirim pesan bebas ke admin
[5]  Panduan Membuat Bot      → tutorial step-by-step buat bot baru
```

### ⚙️ Manajemen Service

```
[1]  Status Service   → lihat status systemd ZiVPN
[2]  Start ZiVPN      → jalankan service
[3]  Stop ZiVPN       → hentikan service
[4]  Restart ZiVPN    → restart service
[5]  Lihat Log        → 60 baris log terakhir
[6]  Ganti Port       → ubah port + update firewall otomatis
```

---

## 🤖 Setup Bot Telegram

### Langkah 1 — Buat Bot

1. Buka Telegram → cari **@BotFather**
2. Kirim `/newbot`
3. Masukkan nama bot, contoh: `OGH ZIV VPN`
4. Masukkan username (harus diakhiri `bot`), contoh: `oghziv_vpn_bot`
5. Salin **TOKEN** yang diberikan

### Langkah 2 — Dapatkan Chat ID

1. Kirim `/start` ke bot kamu
2. Buka URL berikut di browser (ganti `<TOKEN>` dengan token asli):
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
3. Temukan nilai `"id"` di dalam bagian `"from"` — itulah **Chat ID** kamu

### Langkah 3 — Hubungkan ke Script

```
Menu Utama → [4] Telegram Bot → [1] Setup / Konfigurasi Bot
```

Masukkan **Token** dan **Chat ID**, lalu bot siap mengirim notifikasi otomatis setiap ada akun baru, perpanjangan, dan penghapusan.

---

## 🔧 Perintah Cepat Setelah Install

```bash
# Buka menu OGH-ZIV kapan saja
bash ogh-ziv.sh

# Cek status service ZiVPN
systemctl status zivpn

# Restart service
systemctl restart zivpn

# Lihat log real-time
journalctl -u zivpn -f

# Lihat log file
tail -f /etc/zivpn/zivpn.log

# Lihat semua akun
cat /etc/zivpn/users.db

# Cek port yang terbuka
ss -tulpn | grep zivpn
```

---

## 🗑️ Uninstall

Di dalam menu pilih `[7] Uninstall ZiVPN`, lalu ketik `HAPUS` untuk konfirmasi.

Atau manual:

```bash
systemctl stop zivpn
systemctl disable zivpn
rm -f /etc/systemd/system/zivpn.service /usr/local/bin/zivpn
rm -rf /etc/zivpn
systemctl daemon-reload
```

---

## ❓ Troubleshooting

**Service tidak bisa start**
```bash
journalctl -u zivpn -n 50 --no-pager
```

**Port sudah dipakai**
```bash
ss -tulpn | grep 5667
# Ganti port di menu → [5] Manajemen Service → [6] Ganti Port
```

**Binary gagal download**
```bash
# Download manual
wget -O /usr/local/bin/zivpn \
  https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64
chmod +x /usr/local/bin/zivpn
```

**Bot Telegram tidak bisa kirim**
- Pastikan bot sudah di-`/start`
- Verifikasi Chat ID benar
- Cek token di `/etc/zivpn/bot.conf`

---

## 📦 Sumber Binary & Config

| Komponen | URL |
|----------|-----|
| **Binary** | `github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64` |
| **Config template** | `github.com/fauzanihanipah/ziv-udp/raw/main/config.json` |
| **Script** | `github.com/fauzanihanipah/final/raw/main/ogh-ziv.sh` |

---

<div align="center">

**OGH-ZIV** — dibuat dengan ❤️ untuk memudahkan jualan VPN UDP

</div>
