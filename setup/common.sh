#!/bin/bash
# Common functions shared between install.sh and devpod-install.sh

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
    if [ -n "$FISH_PATH" ]; then
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
