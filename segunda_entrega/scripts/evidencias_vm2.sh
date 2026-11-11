#!/usr/bin/env bash
# vm2: guarda en evidencias/ las salidas de diagnóstico (red, puertos, nginx, logs).
# Uso: evidencias_vm2.sh <etiqueta>   (ej. faseA, faseC, fallo_S2, final)
set -uo pipefail
source "$(dirname "$0")/config.sh"
TAG="${1:-final}"; OUT="$EVID/vm2_${TAG}_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p "$EVID"
# Rutas de logs: primero las de la configuración activa (nginx -T), luego las compiladas (nginx -V)
CFG=$(sudo nginx -T 2>/dev/null)
ACC=$(grep -m1 -oE '^\s*access_log\s+[^ ;]+' <<<"$CFG" | awk '{print $2}')
[[ -z "$ACC" ]] && ACC=$(nginx -V 2>&1 | grep -oE 'http-log-path=[^ ]+' | cut -d= -f2)
ERR=$(grep -m1 -oE '^\s*error_log\s+[^ ;]+' <<<"$CFG" | awk '{print $2}')
[[ -z "$ERR" ]] && ERR=$(nginx -V 2>&1 | grep -oE 'error-log-path=[^ ]+' | cut -d= -f2)
ACC=${ACC:-/var/log/nginx/access.log}; ERR=${ERR:-/var/log/nginx/error.log}
# Si los errores van a stderr (valor por defecto en Arch), se leen del journal
if [[ "$ERR" == stderr ]]; then ERR_CMD="sudo journalctl -u nginx -n 40 --no-pager"; else ERR_CMD="sudo tail -n 40 $ERR"; fi
{
  for c in "date" "hostname" "ip -br addr" "ip route" "sudo ss -ltnp" "systemctl is-active nginx" \
           "sudo nginx -t" "nginx -v" "grep -n conf.d $NGINX_CONF" "cat $CONF_DESTINO" \
           "$VENV/bin/python --version" "$VENV/bin/pip show flask" \
           "bash $REPO_DIR/scripts/instancias.sh status" \
           "sudo tail -n 40 $ACC" "$ERR_CMD"; do
    echo "===== \$ $c"; eval "$c" 2>&1; echo
  done
} > "$OUT"
echo "Guardado: $OUT"
