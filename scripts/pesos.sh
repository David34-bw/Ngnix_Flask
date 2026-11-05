#!/usr/bin/env bash
# vm2: cambia SOLO la copia instalada (/etc/nginx/conf.d) entre round robin y 3:1:1.
# El laboratorio.conf del repo no se toca. Uso: pesos.sh rr | ponderado | ver
set -euo pipefail
source "$(dirname "$0")/config.sh"
case "${1:-}" in
  rr)        sudo cp "$CONF_ORIGEN" "$CONF_DESTINO" ;;
  ponderado) sudo cp "$CONF_ORIGEN" "$CONF_DESTINO"
             sudo sed -i -E 's/(server\s+127\.0\.0\.1:5001)(\s|;)/\1 weight=3\2/' "$CONF_DESTINO" ;;
  ver)       ;;
  *) echo "Uso: $0 rr|ponderado|ver"; exit 1 ;;
esac
grep -nE 'upstream|server\s+127' "$CONF_DESTINO"
[[ "$1" == ver ]] || { sudo nginx -t && sudo systemctl reload nginx && echo "NGINX recargado"; }
