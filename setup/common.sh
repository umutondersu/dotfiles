#!/bin/bash
# Common functions shared between installation scripts

# Detect the package manager of the current distribution
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v apk &> /dev/null; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# Check and install Fish shell if needed (via devbox)
ensure_fish_installed() {
    # Activate devbox global environment so its packages are on PATH
    eval "$(devbox global shellenv)" 2>/dev/null || true

    if ! command -v fish &> /dev/null; then
        echo "📦 Fish not found, installing via devbox..."
        devbox global install
        eval "$(devbox global shellenv)" 2>/dev/null || true
        if command -v fish &> /dev/null; then
            echo "✅ Fish installed: $(fish --version)"
        else
            echo "❌ Fish installation via devbox failed"
            exit 1
        fi
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
        echo "📦 Stow not found, installing..."
        local pkg_manager=$(detect_package_manager)
        
        case $pkg_manager in
            apt)
                echo "Installing stow via apt..."
                sudo apt-get update -qq
                sudo apt-get install -y stow
                ;;
            dnf)
                echo "Installing stow via dnf..."
                sudo dnf install -y stow
                ;;
            yum)
                echo "Installing stow via yum..."
                sudo yum install -y stow
                ;;
            pacman)
                echo "Installing stow via pacman..."
                sudo pacman -Sy --noconfirm stow
                ;;
            zypper)
                echo "Installing stow via zypper..."
                sudo zypper install -y stow
                ;;
            apk)
                echo "Installing stow via apk..."
                sudo apk add --no-cache stow
                ;;
            *)
                echo "❌ Error: Could not detect package manager"
                echo "Please install stow manually for your distribution:"
                echo "Or build from source: https://www.gnu.org/software/stow/"
                exit 1
                ;;
        esac
        
        # Verify installation
        if command -v stow &> /dev/null; then
            echo "✅ Stow installed successfully"
        else
            echo "❌ Error: Stow installation failed with package manager $pkg_manager"
            exit 1
        fi
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

# Stow system configuration files (requires sudo)
stow_system_config() {
    echo "🔒 Stowing system configuration files..."
    cd "$SCRIPT_DIR" || exit
    
    # Check if etc directory exists
    if [ ! -d "etc" ]; then
        echo "⚠️  No etc directory found, skipping system config stow"
        return
    fi
    
    # Check for conflicts: directories in dotfiles/etc/ that already exist in /etc/
    local conflicts_found=false
    for dir in etc/*/; do
        if [ -d "$dir" ]; then
            local dirname=$(basename "$dir")
            if [ -e "/etc/$dirname" ] && [ ! -L "/etc/$dirname" ]; then
                if [ ! "$conflicts_found" = true ]; then
                    echo ""
                    echo "⚠️  WARNING: The following directories already exist in /etc:"
                    conflicts_found=true
                fi
                echo "  - /etc/$dirname"
            fi
        fi
    done
    
    if [ "$conflicts_found" = true ]; then
        echo ""
        echo "These existing directories will prevent stow from creating symlinks."
        echo "Skipping system configuration stow to avoid conflicts."
        echo ""
        echo "To manually stow system configuration later:"
        echo "  1. Backup/remove conflicting directories (e.g., sudo mv /etc/udev /etc/udev.backup)"
        echo "  2. Run: sudo stow --target=/etc --dir=$SCRIPT_DIR etc"
        echo ""
        return
    fi
    
    # No conflicts, proceed with stow
    sudo stow --target=/etc etc
    echo "✅ System configuration stowed to /etc"
}

# Setup devbox configuration from template
# Copies the devbox.json template to the working directory
setup_devbox_config() {
    local devbox_global_dir="$HOME/.local/share/devbox/global/default"
    mkdir -p "$devbox_global_dir"
    
    # Copy devbox template (don't symlink - scripts may modify it)
    if [ -f "$SCRIPT_DIR/devbox.json" ]; then
        cp "$SCRIPT_DIR/devbox.json" "$devbox_global_dir/devbox.json"
        echo "✅ Devbox configuration copied from template"
    else
        echo "⚠️  Warning: devbox.json template not found at $SCRIPT_DIR/devbox.json"
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
    FISH_PATH=$(command -v fish)

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

    # Create a stable symlink so tools like kitty/tmux can reference a fixed path
    if [ -L /usr/local/bin/fish ] && [ "$(readlink /usr/local/bin/fish)" = "$FISH_PATH" ]; then
        echo "  ✅ Symlink /usr/local/bin/fish already points to $FISH_PATH"
    else
        echo "  Creating symlink /usr/local/bin/fish -> $FISH_PATH"
        if sudo ln -sf "$FISH_PATH" /usr/local/bin/fish 2>/dev/null; then
            echo "  ✅ Symlink created"
        else
            echo "  ⚠️  Could not create symlink (non-fatal)"
        fi
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

# Setup OpenCode
setup_opencode() {
    echo "💻 Setting up OpenCode..."
    if command -v opencode &> /dev/null; then
        echo "✅ OpenCode already installed: $(opencode --version 2>/dev/null || echo 'installed')"
    else
        bash "$SETUP_DIR/opencode.sh"
        echo "✅ OpenCode installed"
    fi
    echo ""
}
