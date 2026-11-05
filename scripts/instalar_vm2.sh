#!/usr/bin/env bash
# vm2 (servidor): instala NGINX + tmux + venv con Flask, habilita conf.d y carga laboratorio.conf.
set -euo pipefail
source "$(dirname "$0")/config.sh"

for f in app.py laboratorio.conf requirements.txt; do
  [[ -f "$REPO_DIR/$f" ]] || { echo "FALTA $f en $REPO_DIR (archivos del docente)"; exit 1; }
done

echo "== 1. Paquetes (actualización completa, sin -Sy parcial) =="
sudo pacman -Syu --needed --noconfirm nginx curl tmux python iproute2

echo "== 2. venv + Flask =="
[[ -d "$VENV" ]] || python -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install -r "$REPO_DIR/requirements.txt"
"$VENV/bin/python" -c "import flask; print('Flask', flask.__version__)"

echo "== 3. include conf.d en nginx.conf =="
sudo mkdir -p /etc/nginx/conf.d
if grep -Eq '^\s*include\s+/etc/nginx/conf\.d/\*\.conf;' "$NGINX_CONF"; then
  echo "Ya incluye conf.d"
else
  sudo cp -n "$NGINX_CONF" "$NGINX_CONF.orig"
  # Inserta el include justo después de la línea 'http {'
  sudo sed -i '0,/^\s*http\s*{/s//&\n    include \/etc\/nginx\/conf.d\/*.conf;/' "$NGINX_CONF"
  echo "Agregado include (copia original en $NGINX_CONF.orig)"
fi
grep -n 'conf.d' "$NGINX_CONF"

echo "== 4. Copiar laboratorio.conf =="
sudo cp "$CONF_ORIGEN" "$CONF_DESTINO"

echo "== 5. Validar y arrancar NGINX =="
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
systemctl is-active nginx

echo "== 6. Rutas de logs compiladas =="
nginx -V 2>&1 | tr ' ' '\n' | grep -E 'log-path|conf-path' || true
echo "LISTO vm2. IP actual:"; ip -br addr
