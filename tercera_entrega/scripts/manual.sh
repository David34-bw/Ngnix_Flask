#!/usr/bin/env bash
# vm2: fases 2, 3 y 4 SIN Compose (docker build / network / run a mano), como pide la guía.
# Usa nombres m_* para no chocar con Compose; los alias de red flask1..3 permiten usar
# el mismo nginx.conf. Antes de usarlo: bash scripts/lab.sh bajar
# Uso: bash scripts/manual.sh <paso>
#   imagen   Fase 2: construye la imagen y prueba un contenedor suelto (respuesta + logs)
#   red      Fase 3: crea red_manual, 3 contenedores Flask y verifica DNS por nombre
#   nginx    Fase 4: Nginx como 4.º contenedor, publicado en 8080
#   bajar    elimina todo lo creado por este script
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$DIR" || exit 1
D=docker; docker info >/dev/null 2>&1 || D="sudo docker"
IMG=lab-flask:1.0; RED=red_manual
paso() { echo; echo "\$ $*"; "$@"; }

case "${1:-}" in
  imagen)
    paso $D build -t $IMG .
    paso $D image ls $IMG
    paso $D run -d --name m_prueba -e SERVER_ID=prueba $IMG
    sleep 2
    echo; echo "\$ $D exec m_prueba (GET http://127.0.0.1:5000/ dentro del contenedor)"
    $D exec m_prueba python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:5000/').read().decode())"
    paso $D logs m_prueba
    paso $D rm -f m_prueba ;;
  red)
    paso $D network create --driver bridge $RED
    for n in 1 2 3; do
      paso $D run -d --name m_flask$n --network $RED --network-alias flask$n -e SERVER_ID=flask$n $IMG
    done
    sleep 2
    paso $D ps --filter name=m_ --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    echo; echo "\$ $D network inspect $RED"
    $D network inspect $RED -f '{{range .Containers}}{{.Name}}  {{.IPv4Address}}{{"\n"}}{{end}}'
    echo "\$ Desde m_flask1: GET a flask2 y flask3 por nombre"
    for n in 2 3; do
      $D exec m_flask1 python -c "import urllib.request,json; print(json.load(urllib.request.urlopen('http://flask$n:5000/'))['mensaje'])"
    done ;;
  nginx)
    paso $D run -d --name m_nginx --network $RED -p 8080:80 \
         -v "$DIR/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro" nginx:1.28-alpine
    sleep 2
    paso $D ps --filter name=m_ --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    echo; echo "Ahora: bash scripts/lab.sh probar 30" ;;
  bajar)
    $D rm -f m_prueba m_nginx m_flask1 m_flask2 m_flask3 2>/dev/null
    $D network rm $RED 2>/dev/null; echo "Contenedores m_* y red $RED eliminados" ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
