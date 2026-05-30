#!/usr/bin/env bash
# Install Nginx as the TLS-terminating front for Xray (vmess/vless/trojan
# over WebSocket) and the SSH-over-WS bridge. This module is aggressive
# about freeing port 80 because that has been the #1 source of
# "nginx offline" reports — common culprits are apache2 left over from
# previous installs, an old ssh-ws daemon, or a stale nginx default site.

dewa_install_nginx() {
    inst_log "=== NGINX ==="

    # ---- 1. Stop / mask known competitors --------------------------
    # apache2 and httpd both bind 80 by default and would block nginx.
    local svc
    for svc in apache2 httpd lighttpd caddy; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            inst_log "stopping conflicting service: $svc"
            inst_run systemctl stop    "$svc"
            inst_run systemctl disable "$svc"
        fi
    done

    # If something still owns :80 or :443, log it and try to release it.
    local port hog pid
    if command -v ss >/dev/null 2>&1; then
        for port in 80 443; do
            hog=$(ss -tlnp 2>/dev/null | awk -v p=":${port}\$" '$4 ~ p {print $0}' | head -1)
            if [[ -n "$hog" ]]; then
                inst_log "WARN: port ${port} occupied: $hog"
                # Extract pid and only kill if it's not nginx itself.
                pid=$(printf '%s' "$hog" | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2)
                if [[ -n "$pid" ]] && ! grep -q nginx "/proc/${pid}/comm" 2>/dev/null; then
                    inst_log "  killing pid $pid (not nginx) to free port ${port}"
                    kill "$pid" 2>/dev/null || true
                    sleep 1
                fi
            fi
        done
    fi

    # ---- 2. Install ------------------------------------------------
    inst_pkg_install nginx openssl || return 1

    # ---- 3. Cert ---------------------------------------------------
    local crt=/etc/nginx/dewa.crt key=/etc/nginx/dewa.key
    inst_selfsigned_cert "$crt" "$key" "$(hostname)"

    # ---- 4. Config -------------------------------------------------
    # Wipe ALL non-DEWA nginx vhost files. This is more aggressive than
    # just removing /etc/nginx/sites-enabled/default — leftover configs
    # from previous VPN panels (e.g. an old ws-stunnel proxy.conf with
    # its own `listen 80 default_server`) would otherwise produce
    #   "a duplicate default server for 0.0.0.0:80 in /etc/nginx/conf.d/dewa.conf:4"
    # the moment we drop dewa.conf next to them.
    local f
    for f in /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*.conf; do
        [[ -e "$f" ]] || continue
        [[ "$(basename "$f")" == "dewa.conf" ]] && continue
        case "$f" in *.dewa-disabled) continue ;; esac
        mv "$f" "${f}.dewa-disabled"
        inst_log "disabled non-DEWA vhost: $f"
    done
    # Some packages put a `server { listen 80 default_server; }` directly
    # inside /etc/nginx/nginx.conf — neuter that too.
    if grep -qE 'default_server' /etc/nginx/nginx.conf 2>/dev/null; then
        inst_backup_once /etc/nginx/nginx.conf
        sed -i 's/default_server//g' /etc/nginx/nginx.conf
        inst_log "stripped 'default_server' tokens from /etc/nginx/nginx.conf"
    fi

    mkdir -p /var/www/html/.well-known/acme-challenge
    chown -R www-data:www-data /var/www/html 2>/dev/null \
        || chown -R nginx:nginx /var/www/html 2>/dev/null \
        || true
    [[ -f /var/www/html/index.html ]] || echo '<h1>DEWA TUNNELING PANEL</h1>' > /var/www/html/index.html

    inst_write_file /etc/nginx/conf.d/dewa.conf 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
# ---------- Port 80: ACME validation + default landing ----------
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /var/www/html;
    }
    location / {
        return 200 "DEWA TUNNELING PANEL\n";
        add_header Content-Type text/plain;
    }
}

# ---------- Port 443: TLS + WebSocket reverse-proxy ----------
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name _;

    ssl_certificate     ${crt};
    ssl_certificate_key ${key};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers off;

    location = / {
        return 200 "DEWA TUNNELING PANEL\n";
        add_header Content-Type text/plain;
    }

    # Xray inbounds (loopback)
    location /vmess  { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 600s; }
    location /vless  { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 600s; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 600s; }

    # SSH over WebSocket (TLS) — bridged by ws-ssh.service on 8880.
    location /sshws  { proxy_pass http://127.0.0.1:8880;  proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 7d; proxy_send_timeout 7d; }
    location /       { proxy_pass http://127.0.0.1:8880;  proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 7d; proxy_send_timeout 7d; }
}
EOF

    # ---- 5. Test config — fail loudly, on stdout AND in log ------
    if ! nginx -t >/tmp/_nginx_t.log 2>&1; then
        inst_log "nginx config test FAILED:"
        cat /tmp/_nginx_t.log >> "$INSTALL_LOG"
        # Also surface the error to the user immediately.
        echo
        echo "── nginx -t output ──" >&2
        cat /tmp/_nginx_t.log >&2
        echo "──────────────────────" >&2
        rm -f /tmp/_nginx_t.log
        return 1
    fi
    rm -f /tmp/_nginx_t.log

    # ---- 6. Enable + start ----------------------------------------
    inst_systemd_enable nginx
    inst_firewall_open 80 443

    if ! inst_is_active nginx; then
        inst_log "nginx failed to start — diagnostics follow:"
        systemctl status nginx --no-pager >> "$INSTALL_LOG" 2>&1 || true
        journalctl -u nginx -n 50 --no-pager >> "$INSTALL_LOG" 2>&1 || true
        # Inline last 5 journal lines to console.
        echo
        echo "── journalctl -u nginx (last 5) ──" >&2
        journalctl -u nginx -n 5 --no-pager 2>&1 >&2 || true
        echo "──────────────────────────────────" >&2
        return 1
    fi
    return 0
}
