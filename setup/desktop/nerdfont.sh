#!/usr/bin/env bash
set -euo pipefail

# macOS: use ~/Library/Fonts; Linux: use ~/.local/share/fonts
if [[ "$(uname -s)" == "Darwin" ]]; then
    FONT_DIR="$HOME/Library/Fonts"
else
    FONT_DIR="$HOME/.local/share/fonts"
fi

# Arch-based detection
if command -v pacman >/dev/null 2>&1; then
    echo "Arch detected. Installing JetBrains Mono Nerd Font via pacman..."
    if ! sudo pacman -S --needed ttf-jetbrains-mono-nerd; then
        echo "❌ pacman failed to install the font." >&2
        exit 1
    fi
    exit 0
fi

# Fallback: manual install
echo "Non-Arch system detected. Installing JetBrains Mono Nerd Font manually..."

# Check required dependencies
if ! command -v unzip >/dev/null 2>&1; then
    echo "❌ 'unzip' is required but not installed. JetBrainsMono will not be installed." >&2
    exit 0
fi

mkdir -p "$FONT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

if ! curl -fL --connect-timeout 30 --retry 3 --retry-delay 2 "$URL" -o "$TMP_DIR/font.zip"; then
    echo "❌ Failed to download font from $URL" >&2
    exit 1
fi

if ! unzip -q "$TMP_DIR/font.zip" -d "$TMP_DIR"; then
    echo "❌ Failed to extract font archive." >&2
    exit 1
fi

find "$TMP_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$FONT_DIR" \;

# Only run fc-cache on Linux
if [[ "$(uname -s)" != "Darwin" ]] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f
elif [[ "$(uname -s)" != "Darwin" ]]; then
    echo "⚠️ Warning: fc-cache not found. Install fontconfig to refresh font cache."
fi

echo "JetBrains Mono Nerd Font installation complete."
