#!/usr/bin/env bash
# Install Nginx with a minimal default site. Acts as TLS-terminating
# reverse proxy in front of Xray (vmess/vless/trojan over websocket).

dewa_install_nginx() {
    inst_log "=== NGINX ==="

    inst_pkg_install nginx openssl || return 1

    # Self-signed fallback cert — replaced later by acme.sh when a real
    # domain is configured via the panel's "Renew SSL" action.
    local crt=/etc/nginx/dewa.crt key=/etc/nginx/dewa.key
    inst_selfsigned_cert "$crt" "$key" "$(hostname)"

    inst_write_file /etc/nginx/conf.d/dewa.conf 0644 <<EOF
# Managed by DEWA TUNNELING PANEL
server {
    listen 81 default_server;
    listen [::]:81 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
}

server {
    listen 8443 ssl http2;
    listen [::]:8443 ssl http2;
    server_name _;

    ssl_certificate     ${crt};
    ssl_certificate_key ${key};
    ssl_protocols TLSv1.2 TLSv1.3;

    location = / {
        return 200 "DEWA TUNNELING PANEL\n";
        add_header Content-Type text/plain;
    }

    # Reserved websocket endpoints — Xray binds these on loopback.
    location /vmess  { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; }
    location /vless  { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; }
}
EOF

    # Disable the stock default site so it doesn't conflict on :80.
    [[ -f /etc/nginx/sites-enabled/default ]] && rm -f /etc/nginx/sites-enabled/default

    # Make sure /var/www/html exists (used as default root).
    mkdir -p /var/www/html
    [[ -f /var/www/html/index.html ]] || echo '<h1>DEWA TUNNELING PANEL</h1>' > /var/www/html/index.html

    if ! inst_run nginx -t; then
        inst_log "nginx config test failed — see $INSTALL_LOG"
        return 1
    fi
    inst_systemd_enable nginx
    inst_firewall_open 80 81 443 8443
    inst_is_active nginx
}
