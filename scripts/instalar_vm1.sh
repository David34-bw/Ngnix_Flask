#!/usr/bin/env bash
# vm1 (cliente). Uso:
#   bash scripts/instalar_vm1.sh          -> solo curl + python (suficiente para ensayos)
#   bash scripts/instalar_vm1.sh --gui    -> además XFCE + Firefox + guest utils
set -euo pipefail
sudo pacman -Syu --needed --noconfirm curl python iproute2
if [[ "${1:-}" == "--gui" ]]; then
  sudo pacman -S --needed --noconfirm xorg-server xorg-xinit xfce4 firefox virtualbox-guest-utils
  sudo systemctl enable --now vboxservice
  [[ -f ~/.xinitrc ]] || printf 'VBoxClient-all &\nexec startxfce4\n' > ~/.xinitrc
  echo "Arranca la interfaz con: startx"
fi
ip -br addr
