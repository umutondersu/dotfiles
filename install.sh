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
ensure_fish_installed
echo ""

# Step 2: Check if devbox is installed, install if needed
echo "═══════════════════════════════════════"
echo "Step 2/8: Checking for devbox"
echo "═══════════════════════════════════════"
ensure_devbox_installed
echo ""

# Step 3: Install stow if not present
echo "═══════════════════════════════════════"
echo "Step 3/8: Ensuring stow is installed"
echo "═══════════════════════════════════════"
ensure_stow_installed
echo ""

# Step 4: Stow dotfiles (this will symlink devbox.json and all dotfiles)
echo "═══════════════════════════════════════"
echo "Step 4/8: Symlinking dotfiles with stow"
echo "═══════════════════════════════════════"
stow_dotfiles

# Setup devbox configuration from template (not symlinked, can be modified)
setup_devbox_config
echo ""

# Step 5: Install devbox packages
echo "═══════════════════════════════════════"
echo "Step 5/8: Installing devbox packages"
echo "═══════════════════════════════════════"
echo "📦 Installing 21 core packages from devbox.json..."

install_devbox_packages

echo "✅ Core devbox packages installed"
echo ""

# Step 6: Install desktop-specific packages
echo "═══════════════════════════════════════"
echo "Step 6/8: Installing desktop packages"
echo "═══════════════════════════════════════"
echo "📦 Adding desktop-specific packages"

bash "$SETUP_DIR/install-desktop-packages.sh"

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
