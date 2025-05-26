#!/bin/bash

USER=qorcialwolf
KITTY_INSTALL_DIR="/home/$USER/.local/kitty.app"
KITTY_BIN="$KITTY_INSTALL_DIR/bin/kitty"

# 1. Run official Kitty installer
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# 2. Register with update-alternatives
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$KITTY_BIN" 50

# 3. Set Kitty as the default terminal emulator
sudo update-alternatives --set x-terminal-emulator "$HOME/.local/kitty.app/bin/kitty"
