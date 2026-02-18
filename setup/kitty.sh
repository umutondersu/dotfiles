#!/bin/bash
set -e

echo "🐱 Installing Kitty terminal emulator..."

KITTY_INSTALL_DIR="$HOME/.local/kitty.app"
KITTY_BIN="$KITTY_INSTALL_DIR/bin/kitty"

# Check if already installed
if [ -f "$KITTY_BIN" ]; then
    echo "✅ Kitty already installed at $KITTY_BIN"
    echo "Skipping installation..."
    exit 0
fi

# 1. Run official Kitty installer
echo "Downloading and installing kitty..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# 2. Register with update-alternatives (Debian/Ubuntu only)
if command -v update-alternatives &> /dev/null; then
    echo "Registering kitty with update-alternatives..."
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$KITTY_BIN" 50
    
    # 3. Set Kitty as the default terminal emulator
    echo "Setting kitty as default terminal..."
    sudo update-alternatives --set x-terminal-emulator "$KITTY_BIN"
    echo "✅ Kitty set as default terminal via update-alternatives"
else
    echo "ℹ️  update-alternatives not available (non-Debian system)"
    echo "   Kitty installed to: $KITTY_BIN"
    echo "   You can create a symlink or add to PATH if needed"
fi

echo "✅ Kitty terminal installed successfully"
