#!/usr/bin/env bash
# Нагорна і партнери: установка сайта на VPS (Ubuntu/Debian). Запускать от root:  bash setup-vps.sh
set -euo pipefail
DOMAIN=nagornapartners.com
WEB=/var/www/$DOMAIN

echo "== 1/5 Пакеты =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx git certbot python3-certbot-nginx

echo "== 2/5 Файлы сайта =="
rm -rf "$WEB"
git clone --depth 1 -b deploy https://github.com/GreSH1i/nagorna-partners "$WEB"
rm -rf "$WEB/.git" "$WEB/README.md" "$WEB/setup-vps.sh"
chown -R www-data:www-data "$WEB"

echo "== 3/5 Настройка nginx =="
cat > /etc/nginx/sites-available/$DOMAIN <<CONF
server {
    listen 80;
    listen [::]:80;
    server_name www.$DOMAIN;
    return 301 http://$DOMAIN\$request_uri;
}
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $WEB;
    index index.html;
    charset utf-8;
    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;
    location / { try_files \$uri \$uri/ =404; }
    location = /index.html { add_header Cache-Control "no-cache"; }
    location ~* \.(mp4|jpg|jpeg|png|webp|svg|json)\$ { expires 30d; add_header Cache-Control "public"; }
}
CONF
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "== 4/5 Порты 80 и 443 =="
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp; ufw allow 443/tcp; ufw allow OpenSSH
fi

echo "== 5/5 Сертификат HTTPS =="
if certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect; then
  echo "HTTPS включён."
else
  echo "Сертификат не выпущен: скорее всего, DNS домена ещё не указывает на этот сервер."
  echo "Когда DNS обновится, выполните:  certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect"
fi
echo "Готово. Сайт: http://$DOMAIN"
