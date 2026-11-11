#!/usr/bin/env bash
# vm2: ajustes de nginx.conf para Arch (se puede ejecutar varias veces sin duplicar nada).
#  1) error_log en archivo: en Arch el valor compilado es stderr (journal) y la guía pide error.log
#  2) types_hash_max_size: elimina el aviso "could not build optimal types_hash" de nginx -t
set -euo pipefail
source "$(dirname "$0")/config.sh"

sudo cp -n "$NGINX_CONF" "$NGINX_CONF.orig"
grep -q '^error_log' "$NGINX_CONF" || sudo sed -i '1i error_log /var/log/nginx/error.log;' "$NGINX_CONF"
grep -q 'types_hash_max_size' "$NGINX_CONF" || sudo sed -i '0,/^\s*http\s*{/s//&\n    types_hash_max_size 4096;/' "$NGINX_CONF"

grep -nE '^error_log|types_hash_max_size|conf\.d' "$NGINX_CONF"
sudo nginx -t
sudo systemctl reload nginx
systemctl is-active nginx
ls -l /var/log/nginx
