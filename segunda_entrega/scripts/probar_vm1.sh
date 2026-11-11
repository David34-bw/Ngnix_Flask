#!/usr/bin/env bash
# vm1 (cliente): prueba NGINX desde el cliente (Fase C) y guarda la salida como evidencia.
# Uso: bash scripts/probar_vm1.sh [IP_SERVIDOR]    (por defecto 10.0.2.4)
set -uo pipefail
IP="${1:-10.0.2.4}"; BASE="http://$IP:8080"
DIR="$(cd "$(dirname "$0")/.." && pwd)/evidencias"; mkdir -p "$DIR"
OUT="$DIR/vm1_faseC_$(date +%Y%m%d_%H%M%S).txt"
{
  echo "===== $(date '+%F %T')  cliente: $(hostname)"; ip -br addr
  echo; echo "===== 6 x GET $BASE/api/estado (conexión nueva cada vez)"
  for i in 1 2 3 4 5 6; do
    curl -si -H 'Cache-Control: no-cache' "$BASE/api/estado" | grep -aE '^HTTP/|^X-Servidor-Flask|^\{' | tr -d '\r'
    echo
  done
  echo "===== Páginas del portal (código HTTP y réplica que respondió)"
  for p in / /calculadora /pruebas /monitor /health "/api/calcular?a=8&b=2&op=dividir"; do
    curl -s -o /dev/null -w "%{http_code}  %{time_total}s  " "$BASE$p"
    curl -sI "$BASE$p" | grep -ai '^X-Servidor-Flask' | tr -d '\r' | tr '\n' ' '; echo " $p"
  done
  echo; echo "===== Título del portal"
  curl -s "$BASE/" | grep -aoE '<title>[^<]*</title>|<h1>[^<]*</h1>'
  echo; echo "===== /api/calcular?a=8&b=2&op=dividir"
  curl -s "$BASE/api/calcular?a=8&b=2&op=dividir"; echo
} 2>&1 | tee "$OUT"
echo; echo "Guardado: $OUT"
