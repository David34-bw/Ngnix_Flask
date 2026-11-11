#!/usr/bin/env bash
# vm2: gestiona S1/S2/S3 en tmux (sesión "lab", una ventana por instancia).
# Uso: instancias.sh start | stop [S2] | restart S2 | status | ver
set -euo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "$REPO_DIR/logs"

cmd() { echo "cd '$REPO_DIR' && '$VENV/bin/python' -u app.py --id $1 --port ${PUERTOS[$1]} 2>&1 | tee -a logs/$1.log"; }
lanzar() { tmux send-keys -t "$TMUX_SESION:$1" "$(cmd "$1")" C-m; echo "$1 iniciado ($(date +%T.%3N))"; }
detener() { tmux send-keys -t "$TMUX_SESION:$1" C-c; echo "$1 detenido ($(date +%T.%3N))"; }

case "${1:-}" in
  start)
    tmux has-session -t "$TMUX_SESION" 2>/dev/null || tmux new-session -d -s "$TMUX_SESION" -n S1
    for s in S2 S3; do tmux list-windows -t "$TMUX_SESION" -F '#W' | grep -qx $s || tmux new-window -d -t "$TMUX_SESION" -n $s; done
    for s in S1 S2 S3; do lanzar $s; done; sleep 2; bash "$0" status ;;
  stop)    if [[ -n "${2:-}" ]]; then detener "$2"; else for s in S1 S2 S3; do detener $s; done; fi ;;
  restart) detener "$2"; sleep 1; lanzar "$2" ;;
  status)
    for s in S1 S2 S3; do
      printf '%s :%s -> ' $s "${PUERTOS[$s]}"
      curl -s -m 2 "http://127.0.0.1:${PUERTOS[$s]}/api/estado" || printf 'SIN RESPUESTA'; echo
    done ;;
  ver) tmux attach -t "$TMUX_SESION" ;;   # salir sin detener: Ctrl+b y luego d
  *) echo "Uso: $0 start|stop [Sx]|restart Sx|status|ver"; exit 1 ;;
esac
