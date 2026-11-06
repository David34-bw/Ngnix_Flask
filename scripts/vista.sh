#!/usr/bin/env bash
# vm2: pantalla dividida para la demo en vivo.
#   Arriba: 3 paneles con las peticiones que recibe cada réplica (S1 | S2 | S3).
#   Abajo:  consola para comandos (stop/restart S2, pesos, logs).
# Requiere las instancias levantadas: bash scripts/instancias.sh start
# Salir de la vista sin detener nada: Ctrl+b y luego d
set -euo pipefail
source "$(dirname "$0")/config.sh"
S="$TMUX_SESION"
tmux has-session -t "$S" 2>/dev/null || { echo "Primero ejecuta: bash scripts/instancias.sh start"; exit 1; }
mkdir -p "$REPO_DIR/logs"; touch "$REPO_DIR"/logs/S{1,2,3}.log

# Línea de werkzeug -> "hora ruta código" (las demás líneas pasan igual)
FILTRO="sed -u -E 's/^.*\\[[^ ]+ ([0-9:]+)\\] \"([A-Z]+) ([^ ]+) [^\"]*\" ([0-9]+).*/\\1 \\3 \\4/'"

tmux kill-window -t "$S:vista" 2>/dev/null || true
P1=$(tmux new-window -d -P -F '#{pane_id}' -t "$S" -n vista -c "$REPO_DIR")
PC=$(tmux split-window -d -v -l 30% -P -F '#{pane_id}' -t "$P1" -c "$REPO_DIR")
P2=$(tmux split-window -d -h -l 66% -P -F '#{pane_id}' -t "$P1" -c "$REPO_DIR")
P3=$(tmux split-window -d -h -l 50% -P -F '#{pane_id}' -t "$P2" -c "$REPO_DIR")

tmux set-option -w -t "$S:vista" pane-border-status top
tmux set-option -w -t "$S:vista" pane-border-format ' #{pane_title} '
for par in "$P1:S1" "$P2:S2" "$P3:S3"; do
  p=${par%%:*}; s=${par##*:}
  tmux select-pane -t "$p" -T "$s  (puerto ${PUERTOS[$s]})"
  tmux send-keys -t "$p" "clear; tail -n 0 -F logs/$s.log | $FILTRO" C-m
done
tmux select-pane -t "$PC" -T "Comandos"
tmux send-keys -t "$PC" "clear; echo 'Tumbar: bash scripts/instancias.sh stop S2   Levantar: bash scripts/instancias.sh restart S2'" C-m
tmux select-pane -t "$PC"
tmux select-window -t "$S:vista"

if [[ -n "${TMUX:-}" ]]; then tmux switch-client -t "$S:vista"; else tmux attach -t "$S"; fi
