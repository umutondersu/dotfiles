#!/bin/bash
# Clone Neovim configuration

NVIM_DIR="$HOME/.config/nvim"

if [ -d "$NVIM_DIR" ]; then
    echo "✅ Neovim config already exists at $NVIM_DIR, skipping..."
    exit 0
fi

echo "⚙️  Cloning Neovim configuration..."
git clone https://github.com/umutondersu/nvim.git "$NVIM_DIR"
echo "✅ Neovim config cloned"
