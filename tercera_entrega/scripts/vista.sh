#!/usr/bin/env bash
# vm2: pantalla dividida para la demo en vivo (entrega 3).
#   Arriba: 3 paneles con las solicitudes que recibe cada contenedor (flask1 | flask2 | flask3).
#   Abajo:  consola para comandos (bash scripts/lab.sh caer flask2, levantar, etc.).
# Requiere la infraestructura arriba: bash scripts/lab.sh subir
# Salir de la vista sin detener nada: Ctrl+b y luego d
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
D=docker; docker info >/dev/null 2>&1 || D="sudo docker"
S=lab3
command -v tmux >/dev/null || { echo "Falta tmux: sudo pacman -Syu --needed tmux"; exit 1; }

# Sigue los registros del contenedor; si se detiene, espera a que vuelva y continúa.
# Filtro: línea de werkzeug -> "hora ruta código" y oculta los /health del healthcheck.
seguir() {
  local c=$1
  printf '%s' "clear; while :; do $D logs -f --tail 0 $c 2>&1 | grep --line-buffered -v 'GET /health' | sed -u -E 's/^.*\\[[^ ]+ ([0-9:]+)\\] \"[A-Z]+ ([^ ]+) [^\"]*\" ([0-9]+).*/\\1 \\2 \\3/'; echo \"--- $c detenido \$(date +%T) ---\"; until [ \"\$($D inspect -f '{{.State.Running}}' $c 2>/dev/null)\" = true ]; do sleep 1; done; echo \"--- $c activo \$(date +%T) ---\"; done"
}

tmux kill-session -t "$S" 2>/dev/null || true
P1=$(tmux new-session -d -P -F '#{pane_id}' -s "$S" -n vista -c "$DIR" -x "$(tput cols 2>/dev/null || echo 120)" -y "$(tput lines 2>/dev/null || echo 40)")
PC=$(tmux split-window -d -v -l 30% -P -F '#{pane_id}' -t "$P1" -c "$DIR")
P2=$(tmux split-window -d -h -l 66% -P -F '#{pane_id}' -t "$P1" -c "$DIR")
P3=$(tmux split-window -d -h -l 50% -P -F '#{pane_id}' -t "$P2" -c "$DIR")
tmux set-option -w -t "$S:vista" pane-border-status top
tmux set-option -w -t "$S:vista" pane-border-format ' #{pane_title} '
for par in "$P1:flask1" "$P2:flask2" "$P3:flask3"; do
  p=${par%%:*}; c=${par##*:}
  tmux select-pane -t "$p" -T "$c"
  tmux send-keys -t "$p" "$(seguir "$c")" C-m
done
tmux select-pane -t "$PC" -T "Comandos"
tmux send-keys -t "$PC" "clear; echo 'Ej.: bash scripts/lab.sh caer flask2 | levantar flask2 | caer nginx | levantar nginx | probar'" C-m
tmux select-pane -t "$PC"
if [[ -n "${TMUX:-}" ]]; then tmux switch-client -t "$S"; else tmux attach -t "$S"; fi
