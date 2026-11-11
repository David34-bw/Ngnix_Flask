#!/usr/bin/env bash
# Cliente (vm1, o vm2 con 127.0.0.1): menú de experimentos de la entrega 3.
# Uso: bash scripts/menu.sh [IP_SERVIDOR]   (por defecto 10.0.2.4 = vm2)
IP="${1:-10.0.2.4}"; URL="http://$IP:8080"
cd "$(dirname "$0")/.." || exit 1

continuo() {
  echo "1 solicitud cada 0.5 s a $URL/  (Ctrl+C para volver al menú)"
  local n=0
  trap 'echo; return' INT
  while true; do
    n=$((n + 1))
    r=$(curl -s -m 3 -o /dev/null -D - -w 'COD=%{http_code} T=%{time_total}' \
          -H 'Cache-Control: no-cache' "$URL/" | tr -d '\r')
    srv=$(grep -i '^X-Servidor-Flask:' <<<"$r" | awk '{print $2}')
    cod=$(grep -o 'COD=[0-9]*' <<<"$r" | cut -d= -f2)
    t=$(grep -o 'T=[0-9.]*' <<<"$r" | cut -d= -f2)
    ms=$(awk -v t="${t:-0}" 'BEGIN{printf "%.1f", t*1000}')
    if [[ "${cod:-000}" == 000 ]]; then estado="SIN CONEXIÓN"; else estado="HTTP $cod"; fi
    printf '#%-4s %s  %-7s %-13s %7s ms\n' "$n" "$(date +%T)" "${srv:--}" "$estado" "$ms"
    sleep 0.5
  done
}

while true; do
  cat <<EOF

========  Cliente -> Nginx (Docker) $URL  ========
 1) 30 solicitudes con los tres Flask
 2) 30 solicitudes con flask2 detenido    [antes en vm2: bash scripts/lab.sh caer flask2]
 3) Reincorporación de flask2              [elige 3 y luego en vm2: lab.sh levantar flask2]
 4) 30 solicitudes con Nginx detenido     [antes en vm2: bash scripts/lab.sh caer nginx]
 5) Envío continuo en vivo                (Ctrl+C para parar)
 6) Carga pesada                          (300 solicitudes, 20 hilos)
 7) Ver una respuesta completa            (JSON de la ruta /)
 0) Salir
EOF
  read -rp "Opción: " op
  case "$op" in
    1) python3 scripts/ensayos.py tres_flask --ip "$IP" ;;
    2) python3 scripts/ensayos.py sin_flask2 --ip "$IP" ;;
    3) python3 scripts/ensayos.py recuperacion --ip "$IP" ;;
    4) python3 scripts/ensayos.py sin_nginx --ip "$IP" ;;
    5) continuo; trap - INT ;;
    6) python3 scripts/ensayos.py pesada --ip "$IP" ;;
    7) curl -s -i "$URL/" | grep -aE '^HTTP/|^X-Servidor|^X-Upstream|^\{' | tr -d '\r'; echo ;;
    0) exit 0 ;;
    *) echo "Opción no válida" ;;
  esac
done
