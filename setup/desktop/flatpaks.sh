#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLATPAK_LIST="$SCRIPT_DIR/../../flatpak/flatpak-apps.txt"

# Check if flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo "Warning: Flatpak is not installed on this system"
    echo "Skipping Flatpak application installation"
    exit 0
fi

# Check if flatpak-apps.txt exists
if [ ! -f "$FLATPAK_LIST" ]; then
    echo "Error: flatpak-apps.txt not found at $FLATPAK_LIST"
    exit 1
fi

# Ensure flathub remote is configured
if ! flatpak remotes | grep -q "flathub"; then
    echo "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

echo "Installing Flatpak applications..."
if xargs -a "$FLATPAK_LIST" flatpak install -y flathub; then
    echo "Flatpak applications installed successfully"
else
    echo "Some applications may have failed to install"
    echo "You can retry manually with: flatpak install flathub <app-id>"
    exit 1
fi
