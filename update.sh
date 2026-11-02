#!/usr/bin/env bash
# Обновление сайта на VPS: скачивает свежую версию из GitHub и копирует в папку сайта.
set -euo pipefail
WEB=/var/www/nagornapartners.com
TMP=$(mktemp -d)
git clone --depth 1 -b deploy https://github.com/GreSH1i/nagorna-partners "$TMP/np"
rm -rf "$TMP/np/.git" "$TMP/np/README.md" "$TMP/np/setup-vps.sh" "$TMP/np/update.sh"
cp -r "$TMP/np/." "$WEB/"
rm -f "$WEB/setup-vps.sh" "$WEB/update.sh"
chown -R www-data:www-data "$WEB"
rm -rf "$TMP"
echo "Сайт обновлён."
