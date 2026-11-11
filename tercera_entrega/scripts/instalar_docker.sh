#!/usr/bin/env bash
# vm2: instala Docker + Compose en Arch, libera el puerto 8080 de la entrega 2
# y descarga por adelantado las imágenes base. Se puede ejecutar más de una vez.
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "== 0. Kernel en uso vs. módulos instalados"
if [[ ! -d "/usr/lib/modules/$(uname -r)" ]]; then
  echo "El kernel se actualizó y no se ha reiniciado: Docker no podrá cargar sus módulos."
  echo "Ejecuta: sudo reboot   y vuelve a correr este script."; exit 1
fi

echo "== 1. Paquetes (actualización completa, sin -Sy parcial)"
sudo pacman -Syu --needed --noconfirm docker docker-compose tmux curl || exit 1
# buildx: constructor que usa "docker compose build"; si el paquete no existe, se avisa
sudo pacman -S --needed --noconfirm docker-buildx || echo "AVISO: no se instaló docker-buildx"

echo "== 2. Servicio Docker"
sudo systemctl enable --now docker.service
systemctl is-active docker

echo "== 3. Permiso para usar docker sin sudo (efectivo al volver a iniciar sesión)"
sudo usermod -aG docker "$USER"

echo "== 4. Detener la entrega 2 para liberar el puerto 8080"
tmux kill-session -t lab 2>/dev/null && echo "Instancias Flask de la entrega 2 detenidas" || true
sudo systemctl disable --now nginx 2>/dev/null && echo "NGINX nativo detenido y deshabilitado" || true

echo "== 5. Imágenes base (se descargan una sola vez)"
sudo docker pull python:3.13-slim
sudo docker pull nginx:1.28-alpine

echo "== 6. Verificación"
sudo docker version --format 'Docker {{.Server.Version}}'
sudo docker compose version || echo "FALTA docker compose"
sudo docker buildx version 2>/dev/null || echo "AVISO: sin buildx (Compose usará el constructor clásico)"
sudo ss -ltnp | grep -q ':8080 ' && echo "AVISO: algo sigue usando el puerto 8080" || echo "Puerto 8080 libre"
echo
echo "LISTO. Cierra sesión y vuelve a entrar (exit, luego login) para usar docker sin sudo."
echo "Después: cd ~/Ngnix_Flask/tercera_entrega && bash scripts/lab.sh subir"
