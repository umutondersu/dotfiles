#!/bin/bash
# Common functions shared between install.sh and devpod-install.sh

# Check and install Fish shell if needed
ensure_fish_installed() {
    if ! command -v fish &> /dev/null; then
        bash "$SETUP_DIR/fish.sh"
    else
        echo "✅ Fish already installed: $(fish --version)"
    fi
}

# Check and install devbox if needed
ensure_devbox_installed() {
    if ! command -v devbox &> /dev/null; then
        echo "📦 Devbox not found, installing..."
        # Use -f flag to skip interactive prompts (required for non-TTY environments)
        curl -fsSL https://get.jetify.com/devbox | bash -s -- -f
        
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
}

# Check and install stow if needed
ensure_stow_installed() {
    if ! command -v stow &> /dev/null; then
        if ! command -v apt-get &> /dev/null; then
            echo "❌ Error: apt-get not found. This script requires a Debian-based system (Ubuntu, Debian, etc.)"
            echo "Please install stow manually for your distribution"
            exit 1
        fi
        echo "Installing stow via apt..."
        sudo apt-get update -qq
        sudo apt-get install -y stow
        echo "✅ Stow installed"
    else
        echo "✅ Stow already installed"
    fi
}

# Run stow to symlink dotfiles
stow_dotfiles() {
    cd "$SCRIPT_DIR" || exit
    stow . --adopt
    echo "✅ Dotfiles symlinked"
}

# Setup devbox configuration from template
# Copies the devbox.json template to the working directory
setup_devbox_config() {
    local devbox_global_dir="$HOME/.local/share/devbox/global/default"
    mkdir -p "$devbox_global_dir"
    
    # Copy devbox template (don't symlink - scripts may modify it)
    if [ -f "$SCRIPT_DIR/.devbox/devbox.json" ]; then
        cp "$SCRIPT_DIR/.devbox/devbox.json" "$devbox_global_dir/devbox.json"
        echo "✅ Devbox configuration copied from template"
    else
        echo "⚠️  Warning: devbox.json template not found at $SCRIPT_DIR/.devbox/devbox.json"
    fi
}

# Install devbox global packages from devbox.json
install_devbox_packages() {
    echo "📦 Installing devbox packages from devbox.json..."
    devbox global install
    echo "✅ Devbox packages installed"
}

# Clone Neovim configuration
setup_neovim_config() {
    echo "⚙️  Setting up Neovim configuration..."
    NVIM_DIR="$HOME/.config/nvim"
    if [ ! -d "$NVIM_DIR" ]; then
        git clone https://github.com/umutondersu/nvim.git "$NVIM_DIR"
        echo "✅ Neovim config cloned"
    else
        echo "⚠️  Neovim config already exists, skipping..."
    fi
    echo ""
}

# Set Fish as default shell with resilient error handling
setup_fish_shell() {
    echo "🐚 Setting Fish as default shell..."
    FISH_PATH=$(command -v fish 2>/dev/null || true)
    if [ "$FISH_PATH" != "" ]; then
        # Add Fish to /etc/shells if not already there
        if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
            echo "  Adding Fish to /etc/shells..."
            if echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null 2>&1; then
                echo "  ✅ Fish added to /etc/shells"
            else
                echo "  ⚠️  Could not add Fish to /etc/shells (non-fatal)"
            fi
        fi
        
        # Try to change default shell
        if [ "$SHELL" != "$FISH_PATH" ]; then
            echo "  Attempting to change default shell to Fish..."
            if sudo chsh -s "$FISH_PATH" "$USER" 2>/dev/null; then
                echo "  ✅ Default shell changed to Fish ($FISH_PATH)"
                echo "  ⚠️  Please log out and log back in for shell change to take effect"
            else
                echo "  ⚠️  Could not change default shell automatically"
                echo "  💡 You can start Fish manually by running: fish"
                echo "  💡 Or set it as default later with: chsh -s $FISH_PATH"
            fi
        else
            echo "  ✅ Fish is already the default shell"
        fi
    else
        echo "  ⚠️  Fish not found in PATH"
    fi
    
    # Configure git to ignore local changes to fish_variables (Tide prompt cache)
    echo "  Configuring git to ignore fish_variables cache changes..."
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ -f "$DOTFILES_DIR/.config/fish/fish_variables" ]; then
        if git -C "$DOTFILES_DIR" update-index --assume-unchanged .config/fish/fish_variables 2>/dev/null; then
            echo "  ✅ Git will ignore fish_variables cache changes"
        else
            echo "  ⚠️  Could not set git assume-unchanged (non-fatal)"
        fi
    fi
    
    echo ""
}

# Setup Tmux Plugin Manager (TPM) - Desktop only
setup_tpm() {
    echo "📦 Setting up Tmux Plugin Manager (TPM)..."
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        echo "✅ TPM cloned successfully"
        echo "ℹ️  To install tmux plugins:"
        echo "   1. Start tmux: tmux"
        echo "   2. Press <Ctrl-Space> + I to install plugins"
    else
        echo "✅ TPM already installed, skipping..."
    fi
    echo ""
}
