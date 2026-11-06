#!/usr/bin/env bash
# vm1 (cliente): menú para enviar peticiones a NGINX durante la demo.
# Uso: bash scripts/menu.sh [IP_SERVIDOR]   (por defecto 10.0.2.4)
IP="${1:-10.0.2.4}"; URL="http://$IP:8080"
cd "$(dirname "$0")/.." || exit 1

continuo() {
  echo "Enviando 1 petición cada 0.5 s a $URL/api/estado  (Ctrl+C para volver al menú)"
  local n=0
  trap 'echo; return' INT
  while true; do
    n=$((n + 1))
    r=$(curl -s -m 3 -o /dev/null -D - -w 'COD=%{http_code} T=%{time_total}' \
          -H 'Cache-Control: no-cache' "$URL/api/estado" | tr -d '\r')
    srv=$(grep -i '^X-Servidor-Flask:' <<<"$r" | awk '{print $2}')
    cod=$(grep -o 'COD=[0-9]*' <<<"$r" | cut -d= -f2)
    t=$(grep -o 'T=[0-9.]*' <<<"$r" | cut -d= -f2)
    ms=$(awk -v t="${t:-0}" 'BEGIN{printf "%.1f", t*1000}')
    printf '#%-4s %s  %-3s  HTTP %s  %6s ms\n' "$n" "$(date +%T)" "${srv:--}" "${cod:-000}" "$ms"
    sleep 0.5
  done
}

while true; do
  cat <<EOF

========  Cliente -> NGINX $URL  ========
 1) Round robin        (30 peticiones)
 2) Pesos 3:1:1        (50 peticiones)   [antes en vm2: pesos.sh ponderado]
 3) Fallo              (30 peticiones)   [antes en vm2: stop S2]
 4) Recuperación       (espera a S2)     [luego en vm2: restart S2]
 5) Carga pesada       (300 peticiones, 20 hilos)
 6) Envío continuo     (en vivo, Ctrl+C para parar)
 7) Cliente del docente (cliente_pruebas.py, 30 peticiones)
 8) Portal y páginas   (probar_vm1.sh)
 0) Salir
EOF
  read -rp "Opción: " op
  case "$op" in
    1) python3 scripts/ensayos.py rr --ip "$IP" ;;
    2) python3 scripts/ensayos.py ponderado --ip "$IP" ;;
    3) python3 scripts/ensayos.py fallo --ip "$IP" ;;
    4) python3 scripts/ensayos.py recuperacion --ip "$IP" ;;
    5) python3 scripts/ensayos.py pesada --ip "$IP" ;;
    6) continuo; trap - INT ;;
    7) python3 cliente_pruebas.py --url "$URL" -n 30 ;;
    8) bash scripts/probar_vm1.sh "$IP" ;;
    0) exit 0 ;;
    *) echo "Opción no válida" ;;
  esac
done
