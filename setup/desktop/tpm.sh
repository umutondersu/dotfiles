#!/usr/bin/env bash
# Setup Tmux Plugin Manager (TPM)

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
    echo "✅ TPM already installed, skipping..."
    exit 0
fi

echo "📦 Cloning Tmux Plugin Manager (TPM)..."
git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
echo "✅ TPM cloned successfully"
echo "ℹ️  To install tmux plugins:"
echo "   1. Start tmux: tmux"
echo "   2. Press <Ctrl-Space> + I to install plugins"
