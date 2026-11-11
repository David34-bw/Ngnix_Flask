#!/usr/bin/env bash
# vm2: control de la infraestructura Docker (entrega 3).
# Uso: bash scripts/lab.sh <comando> [argumento]
#   subir                 docker compose up -d --build (despliegue completo)
#   estado                contenedores, salud y 3 solicitudes de prueba
#   probar [N]            N solicitudes a localhost:8080 mostrando la instancia (30 por defecto)
#   red                   red privada: IPs, DNS interno y puertos publicados
#   caer <servicio>       detiene flask1|flask2|flask3|nginx
#   levantar <servicio>   vuelve a iniciar el servicio
#   fallar <flaskN>       simula una caída del proceso (prueba la política de reinicio)
#   logs [servicio]       últimos registros (nginx muestra a qué instancia envió cada solicitud)
#   reconstruir           down + up -d --build (reconstrucción completa)
#   bajar                 docker compose down
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$DIR" || exit 1
DOCKER=docker; docker info >/dev/null 2>&1 || DOCKER="sudo docker"
DC="$DOCKER compose"

desplegar() {   # up -d --build; si no hay buildx, construye con "docker build" y luego levanta
  if $DOCKER buildx version >/dev/null 2>&1; then $DC up -d --build
  else echo "(sin buildx: docker build + compose up)"; $DOCKER build -t lab-flask:1.0 . && $DC up -d; fi
}

servidor() {   # una solicitud: imprime "instancia código tiempo"
  curl -s -m 5 -o /dev/null -D - -w 'COD=%{http_code} T=%{time_total}\n' localhost:8080/ 2>/dev/null | tr -d '\r' |
    awk '/^X-Servidor-Flask:/{s=$2} /^COD=/{split($1,c,"=");split($2,t,"="); printf "%-7s HTTP %s  %.3f s\n", (s?s:"-"), c[2], t[2]}'
}

case "${1:-}" in
  subir)       desplegar && sleep 3 && bash "$0" estado ;;
  estado)      $DC ps -a --format 'table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
               echo; echo "3 solicitudes a localhost:8080:"; for i in 1 2 3; do servidor; done ;;
  probar)      n="${2:-30}"; declare -A c=(); err=0
               for i in $(seq 1 "$n"); do
                 l=$(servidor); [[ -z "$l" ]] && l="-       HTTP 000  sin conexión"
                 printf '#%-3s %s\n' "$i" "$l"; s=${l%% *}; cod=$(awk '{print $3}' <<<"$l")
                 if [[ "$cod" == 200 ]]; then c[$s]=$(( ${c[$s]:-0} + 1 )); else err=$((err + 1)); fi
               done
               echo "--- Resumen ($n solicitudes)"
               for s in $(printf '%s\n' "${!c[@]}" | sort); do printf '%-7s %3s  (%5.1f %%)\n' "$s" "${c[$s]}" "$(awk -v a="${c[$s]}" -v n="$n" 'BEGIN{print a*100/n}')"; done
               printf '%-7s %3s\n' errores "$err" ;;
  red)         echo "== Red red_lab (contenedores e IPs)"
               $DOCKER network inspect red_lab -f '{{range .Containers}}{{.Name}}  {{.IPv4Address}}{{"\n"}}{{end}}'
               echo "== DNS interno visto desde el contenedor nginx"
               $DOCKER exec nginx getent hosts flask1 flask2 flask3
               echo "== flask1 consulta a flask2 por nombre (red interna)"
               $DOCKER exec flask1 python -c "import urllib.request,json; print(json.load(urllib.request.urlopen('http://flask2:5000/'))['mensaje'])"
               echo "== Puertos publicados en el anfitrión"
               for s in flask1 flask2 flask3 nginx; do printf '%-7s %s\n' "$s" "$($DOCKER port "$s" | tr '\n' ' ')"; done
               curl -s -m 2 -o /dev/null localhost:5000 && echo "localhost:5000 accesible (NO esperado)" || echo "localhost:5000 no accesible desde el anfitrión (esperado)" ;;
  caer)        $DC stop "${2:?falta servicio: flask1|flask2|flask3|nginx}" ;;
  levantar)    $DC start "${2:?falta servicio}" ;;
  fallar)      s="${2:?falta servicio: flask1|flask2|flask3}"
               echo "Terminando el proceso principal de $s (como si fallara la aplicación)..."
               $DOCKER exec "$s" python -c "import os,signal; os.kill(1, signal.SIGTERM)"
               sleep 3; $DOCKER inspect -f '{{.Name}}: estado={{.State.Status}} reinicios={{.RestartCount}}' "$s" ;;
  logs)        $DC logs --tail 20 ${2:-} ;;
  reconstruir) $DC down && desplegar && sleep 3 && bash "$0" estado ;;
  bajar)       $DC down ;;
  *)           sed -n '2,14p' "$0"; exit 1 ;;
esac
