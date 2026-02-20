#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/setup"

# Source common functions
source "$SETUP_DIR/common.sh"

# Parse command line arguments
INSTALL_MODE="devenv"  # default to dev environment installation

while [[ $# -gt 0 ]]; do
    case $1 in
        --devenv)
            INSTALL_MODE="devenv"
            shift
            ;;
        --desktop)
            INSTALL_MODE="desktop"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--devenv|--desktop]"
            echo ""
            echo "Options:"
            echo "  --devenv    Install development environment (default)"
            echo "  --desktop   Install full desktop environment"
            echo "  -h, --help  Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# Display banner based on mode
if [ "$INSTALL_MODE" = "devenv" ]; then
    echo "╔════════════════════════════════════════╗"
    echo "║  Dotfiles Installation (Dev Env)      ║"
    echo "╚════════════════════════════════════════╝"
    echo "Installing development environment"
else
    echo "╔════════════════════════════════════════╗"
    echo "║  Dotfiles Installation (Desktop)       ║"
    echo "╚════════════════════════════════════════╝"
    echo "Installing full desktop environment with GUI tools"
fi
echo ""

# Core installation steps (common to both modes)
echo "═══════════════════════════════════════"
echo "Step 1: Installing Fish shell"
echo "═══════════════════════════════════════"
ensure_fish_installed
echo ""

echo "═══════════════════════════════════════"
echo "Step 2: Checking for devbox"
echo "═══════════════════════════════════════"
ensure_devbox_installed
echo ""

echo "═══════════════════════════════════════"
echo "Step 3: Ensuring stow is installed"
echo "═══════════════════════════════════════"
ensure_stow_installed
echo ""

echo "═══════════════════════════════════════"
echo "Step 4: Symlinking dotfiles with stow"
echo "═══════════════════════════════════════"
stow_dotfiles
setup_devbox_config
echo ""

echo "═══════════════════════════════════════"
echo "Step 5: Installing devbox packages"
echo "═══════════════════════════════════════"
echo "📦 Installing core packages from devbox.json..."
install_devbox_packages
echo "✅ Core devbox packages installed"
echo ""

# Desktop-specific installation steps
if [ "$INSTALL_MODE" = "desktop" ]; then
    echo "═══════════════════════════════════════"
    echo "Step 6: Stowing system configuration"
    echo "═══════════════════════════════════════"
    stow_system_config
    echo ""
    
    echo "═══════════════════════════════════════"
    echo "Step 7: Installing desktop packages"
    echo "═══════════════════════════════════════"
    echo "📦 Adding desktop-specific packages"
    bash "$SETUP_DIR/install-desktop-packages.sh"
    echo "✅ Desktop packages installed"
    echo ""
    
    echo "All installed packages:"
    devbox global list
    echo ""
    
    echo "═══════════════════════════════════════"
    echo "Step 9: Setting up Kitty terminal"
    echo "═══════════════════════════════════════"
    bash "$SETUP_DIR/kitty.sh"
    echo ""
    
    echo "═══════════════════════════════════════"
    echo "Step 10: Setting up nerd-dictation"
    echo "═══════════════════════════════════════"
    bash "$SETUP_DIR/nerd-dictation.sh"
    bash "$SETUP_DIR/vosk-install.sh"
    echo ""
    
    echo "═══════════════════════════════════════"
    echo "Step 11: Installing Flatpak applications"
    echo "═══════════════════════════════════════"
    bash "$SETUP_DIR/install-flatpaks.sh"
    echo ""
fi

# Post-installation (common to both modes)
echo "═══════════════════════════════════════"
echo "Post-installation setup"
echo "═══════════════════════════════════════"

setup_neovim_config

# Desktop-only: Setup TPM
if [ "$INSTALL_MODE" = "desktop" ]; then
    setup_tpm
fi

setup_opencode
setup_fish_shell

echo "🎉 Post-installation complete!"
echo ""

# Final message
echo "╔═══════════════════════════════════════════════════╗"
echo "║          Installation Complete! 🎉                ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

if [ "$INSTALL_MODE" = "devenv" ]; then
    echo "Development environment installed!"
    echo ""
    echo "Core packages installed:"
    echo "  Shell: fzf, ripgrep, fd, zoxide, bat, lsd, thefuck, tldr, direnv"
    echo "  Editor: neovim, opencode"
    echo "  Development: go, nodejs_22, python312, deno, fish-lsp"
    echo "  Git tools: lazygit, lazydocker"
    echo "  File manager: superfile"
    echo "  Network: curlie, posting, vegeta"
    echo "  Disk: dysk"
    echo ""
else
    echo "Desktop environment installed!"
    echo ""
fi

echo "Next steps:"
echo "  1. Log out and log back in (for Fish shell to take effect)"
echo "  2. Open a new terminal - devbox packages will be automatically loaded"
echo "  3. Test your tools: nvim, opencode, lazygit, fzf, etc."

if [ "$INSTALL_MODE" = "desktop" ]; then
    echo "  4. In tmux: Press <Ctrl-Space> + I to install tmux plugins"
fi

echo ""
echo "Manage packages:"
echo "  - Add: devbox global add <package>"
echo "  - Remove: devbox global rm <package>"
echo "  - List: devbox global list"
echo "  - Update: devbox global update"
echo "  - Edit: ~/.local/share/devbox/global/default/devbox.json"
echo ""
