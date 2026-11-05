#!/usr/bin/env bash
# Configuración común. Ajusta aquí si cambian IPs o puertos.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$REPO_DIR/venv"
TMUX_SESION="lab"
declare -A PUERTOS=( [S1]=5001 [S2]=5002 [S3]=5003 )
CONF_ORIGEN="$REPO_DIR/laboratorio.conf"
CONF_DESTINO="/etc/nginx/conf.d/laboratorio.conf"
NGINX_CONF="/etc/nginx/nginx.conf"
EVID="$REPO_DIR/evidencias"
