#!/usr/bin/env bash
# Install AUR packages and extra repositories on a new Arch-based machine

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
AUR_DIR="$DOTFILES_DIR/aur"

echo "==> Adding extra repositories to /etc/pacman.conf..."
sudo tee -a /etc/pacman.conf < "$AUR_DIR/extra-repos.conf"

echo "==> Syncing package databases..."
sudo pacman -Sy

echo "==> Installing AUR packages..."
paru -S --needed - < "$AUR_DIR/aur-packages.txt"

echo "Done."
