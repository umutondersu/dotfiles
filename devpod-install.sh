#!/bin/bash
set -e

# Get script directory and source common functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/setup/common.sh"

echo "=========================================="
echo "DevPod/Remote Dotfiles Installation"
echo "=========================================="
echo "This script installs a minimal development environment"
echo "suitable for SSH sessions, remote environments, and containers."
echo ""

# Step 1: Check if devbox is installed, install if not
echo "Step 1: Checking for devbox installation..."
if ! command -v devbox &> /dev/null; then
    echo "  devbox not found. Installing devbox..."
    curl -fsSL https://get.jetify.com/devbox | bash
    
    # Source devbox in current shell
    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v devbox &> /dev/null; then
        echo "  ✓ devbox installed successfully"
    else
        echo "  ✗ Failed to install devbox"
        exit 1
    fi
else
    echo "  ✓ devbox is already installed"
fi
echo ""

# Step 2: Install stow if not present
echo "Step 2: Checking for stow..."
if ! command -v stow &> /dev/null; then
    echo "  stow not found. Installing via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y stow
    echo "  ✓ stow installed"
else
    echo "  ✓ stow is already installed"
fi
echo ""

# Step 3: Stow dotfiles and install devbox packages
echo "Step 3: Symlinking dotfiles with stow..."
cd "$SCRIPT_DIR"

# Use --adopt to handle existing files (user's preferred method)
stow . --adopt

echo "  ✓ Dotfiles symlinked"
echo ""

echo "Step 4: Installing devbox packages..."
echo "  This will install 21 core development packages via Nix..."
echo "  (This may take several minutes on first run)"
echo ""

# Install all packages from devbox.json
devbox global install

echo ""
echo "  ✓ Devbox packages installed"
echo ""

# Step 5: Post-installation setup
echo "Step 5: Post-installation setup..."
echo ""

# Setup Neovim configuration
setup_neovim_config

# Setup Fish shell
setup_fish_shell

echo "=========================================="
echo "DevPod/Remote Installation Complete!"
echo "=========================================="
echo ""
echo "Core packages installed (21):"
echo "  Shell: fish, fzf, ripgrep, fd, zoxide, bat, lsd, thefuck, tldr"
echo "  Editor: neovim"
echo "  Development: go, nodejs_22, python312, deno, fish-lsp"
echo "  Git tools: lazygit, lazydocker"
echo "  File manager: superfile"
echo "  Network: curlie, posting, vegeta"
echo "  Disk: dysk"
echo ""
echo "To verify installation:"
echo "  devbox global list"
echo ""
echo "Start using your environment:"
echo "  1. Log out and log back in (or run: exec fish)"
echo "  2. All devbox tools are automatically available in Fish"
echo ""
