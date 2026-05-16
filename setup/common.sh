#!/usr/bin/env bash
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

# Check and install devbox if needed
ensure_devbox_installed() {
    bash "$SETUP_DIR/core/devbox.sh"
    # Re-export PATH in case devbox was just installed
    export PATH="$HOME/.local/bin:$PATH"
}

# Check and install stow if needed
ensure_stow_installed() {
    bash "$SETUP_DIR/core/stow.sh"
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
                    echo "⚠️ Warning: The following directories already exist in /etc:"
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
    bash "$SETUP_DIR/tools/neovim.sh"
    echo ""
}

# Set Fish as default shell with resilient error handling
setup_fish_shell() {
    bash "$SETUP_DIR/core/fish/setup-shell.sh"
    echo ""
}

# Setup Tmux Plugin Manager (TPM) - Desktop only
setup_tpm() {
    bash "$SETUP_DIR/desktop/tpm.sh"
    echo ""
}
