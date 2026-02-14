#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/setup"

# Source common functions
source "$SETUP_DIR/common.sh"

echo "╔════════════════════════════════════════╗"
echo "║  Dotfiles Installation (Devbox-based) ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Step 1: Install Fish shell (required before devbox)
echo "═══════════════════════════════════════"
echo "Step 1/8: Installing Fish shell"
echo "═══════════════════════════════════════"
if ! command -v fish &> /dev/null; then
    bash "$SETUP_DIR/fish.sh"
else
    echo "✅ Fish already installed: $(fish --version)"
fi
echo ""

# Step 2: Check if devbox is installed, install if needed
echo "═══════════════════════════════════════"
echo "Step 2/8: Checking for devbox"
echo "═══════════════════════════════════════"
if ! command -v devbox &> /dev/null; then
    echo "📦 Devbox not found, installing..."
    curl -fsSL https://get.jetify.com/devbox | bash
    
    # Source the devbox environment
    export PATH="$HOME/.local/bin:$PATH"
    
    # Verify installation
    if ! command -v devbox &> /dev/null; then
        echo "❌ Error: Devbox installation failed"
        echo "Please install manually: https://www.jetify.com/devbox/docs/installing_devbox/"
        exit 1
    fi
    
    echo "✅ Devbox installed successfully: $(devbox version)"
else
    echo "✅ Devbox found: $(devbox version)"
fi
echo ""

# Step 3: Install stow if not present
echo "═══════════════════════════════════════"
echo "Step 3/8: Ensuring stow is installed"
echo "═══════════════════════════════════════"
if ! command -v stow &> /dev/null; then
    echo "Installing stow via apt..."
    sudo apt update
    sudo apt install stow -y
else
    echo "✅ Stow already installed"
fi
echo ""

# Step 4: Stow dotfiles (this will symlink devbox.json and all dotfiles)
echo "═══════════════════════════════════════"
echo "Step 4/8: Symlinking dotfiles with stow"
echo "═══════════════════════════════════════"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$HOME/.local/share/devbox/global/default"

cd "$SCRIPT_DIR"
stow . --adopt

echo "✅ Dotfiles symlinked (including devbox.json)"
echo ""

# Step 5: Install devbox packages
echo "═══════════════════════════════════════"
echo "Step 5/8: Installing devbox packages"
echo "═══════════════════════════════════════"
echo "📦 Installing 21 core packages from devbox.json..."

# Install packages from devbox.json
devbox global install

echo "✅ Core devbox packages installed"
echo ""

# Step 6: Install desktop-specific packages
echo "═══════════════════════════════════════"
echo "Step 6/8: Installing desktop packages"
echo "═══════════════════════════════════════"
echo "📦 Adding desktop-specific packages"

devbox global add tmux@3.2a streamrip@latest yt-dlp@latest dysk@3.4.0

echo "✅ Desktop packages installed"
echo ""
echo "All installed packages:"
devbox global list
echo ""

# Step 7: Install kitty
echo "═══════════════════════════════════════"
echo "Step 7/8: Setting up Kitty terminal"
echo "═══════════════════════════════════════"
bash "$SETUP_DIR/kitty.sh"
echo ""

# Step 8: Install nerd-dictation + vosk
echo "═══════════════════════════════════════"
echo "Step 8/8: Setting up nerd-dictation"
echo "═══════════════════════════════════════"
bash "$SETUP_DIR/nerd-dictation.sh"
bash "$SETUP_DIR/vosk-install.sh"
echo ""

# Post-installation
echo "═══════════════════════════════════════"
echo "Post-installation setup"
echo "═══════════════════════════════════════"

# Setup Neovim configuration
setup_neovim_config

# Setup Tmux Plugin Manager (Desktop only)
setup_tpm

# Setup Fish shell
setup_fish_shell

echo "🎉 Post-installation complete!"
echo ""

# Final message
echo "╔═══════════════════════════════════════════════════╗"
echo "║          Installation Complete! 🎉                ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (for Fish shell to take effect)"
echo "  2. Open a new terminal - devbox packages will be automatically loaded"
echo "  3. Test your tools: nvim, lazygit, fzf, etc."
echo "  4. In tmux: Press <Ctrl-Space> + I to install tmux plugins"
echo ""
echo "Manage packages:"
echo "  - Add: devbox global add <package>"
echo "  - Remove: devbox global rm <package>"
echo "  - List: devbox global list"
echo "  - Update: devbox global update"
echo "  - Edit: ~/.local/share/devbox/global/default/devbox.json"
echo ""
