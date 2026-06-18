#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/setup"
DESKTOP_DIR="$SETUP_DIR/desktop"

# Detect OS
OS="linux"
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macos"
fi

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
    echo "Installing development environment (OS: $OS)"
else
    echo "╔════════════════════════════════════════╗"
    echo "║  Dotfiles Installation (Desktop)       ║"
    echo "╚════════════════════════════════════════╝"
    echo "Installing full desktop environment with GUI tools (OS: $OS)"
fi
echo ""

# Core installation steps (common to both modes)
echo "═══════════════════════════════════════"
echo "Checking for devbox"
echo "═══════════════════════════════════════"
if [ "$OS" = "macos" ]; then
    ensure_homebrew_installed
fi
ensure_devbox_installed
echo ""

echo "═══════════════════════════════════════"
echo "Ensuring stow is installed"
echo "═══════════════════════════════════════"
ensure_stow_installed
echo ""

echo "═══════════════════════════════════════"
echo "Symlinking dotfiles with stow"
echo "═══════════════════════════════════════"
stow_dotfiles
setup_devbox_config
echo ""

echo "═══════════════════════════════════════"
echo "Installing devbox packages"
echo "═══════════════════════════════════════"
echo "📦 Installing core packages from devbox.json..."
install_devbox_packages
echo "✅ Core devbox packages installed"
echo ""

echo "═══════════════════════════════════════"
echo "Installing Fish shell"
echo "═══════════════════════════════════════"
ensure_fish_installed
echo ""

if [ "$OS" = "macos" ]; then
    echo "═══════════════════════════════════════"
    echo "Installing Mac specific configuration"
    echo "═══════════════════════════════════════"
    setup_gitconfig_macos
    echo ""

    echo "═══════════════════════════════════════"
    echo "Installing Homebrew packages (Brewfile)"
    echo "═══════════════════════════════════════"
    install_brewfile
    echo ""
fi

# Steps 6-9: Desktop-only installation
if [ "$INSTALL_MODE" = "desktop" ]; then
    echo "═══════════════════════════════════════"
    echo "Stowing system configuration"
    echo "═══════════════════════════════════════"
    if [ "$OS" = "macos" ]; then
        echo "⏭️  Skipping system config stow (not applicable on macOS)"
    else
        stow_system_config
    fi
    echo ""

    echo "═══════════════════════════════════════"
    echo "Installing desktop packages"
    echo "═══════════════════════════════════════"
    echo "📦 Adding desktop-specific packages"
    bash "$DESKTOP_DIR/packages.sh"
    echo "✅ Desktop packages installed"
    echo ""

    echo "All installed packages:"
    devbox global list
    echo ""

    echo "═══════════════════════════════════════"
    echo "Setting up Kitty terminal"
    echo "═══════════════════════════════════════"
    bash "$DESKTOP_DIR/kitty.sh"
    echo ""

    echo "═══════════════════════════════════════"
    echo "Installing Flatpak applications"
    echo "═══════════════════════════════════════"
    if [ "$OS" = "macos" ]; then
        echo "⏭️  Skipping Flatpak (not available on macOS)"
    else
        bash "$DESKTOP_DIR/flatpaks.sh"
    fi
    echo ""

    echo "═══════════════════════════════════════"
    echo "Installing JetBrainsMono Nerd Font"
    echo "═══════════════════════════════════════"
    bash "$DESKTOP_DIR/nerdfont.sh"
    echo ""

    if [ "$OS" = "linux" ] && [ "$(detect_package_manager)" = "pacman" ]; then
        echo "═══════════════════════════════════════"
        echo "Installing AUR packages"
        echo "═══════════════════════════════════════"
        bash "$DESKTOP_DIR/aur.sh"
        echo ""
    fi

fi

# Post-installation (common to both modes — always runs)
echo "═══════════════════════════════════════"
echo "Post-installation setup"
echo "═══════════════════════════════════════"

setup_neovim_config
setup_fish_shell

# Desktop-only: Setup TPM
if [ "$INSTALL_MODE" = "desktop" ]; then
    setup_tpm
fi

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
