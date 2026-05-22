#!/usr/bin/env bash
# Set Fish as the default shell, create stable symlink, configure git, install plugins

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# Configure git to ignore local changes to fish_variables (Tide prompt cache)
echo "  Configuring git to ignore fish_variables cache changes..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if git -C "$DOTFILES_DIR" update-index --skip-worktree .config/fish/fish_variables 2>/dev/null; then
    echo "  ✅ Git will ignore fish_variables cache changes"
else
    echo "  ⚠️  Could not set git skip-worktree (non-fatal)"
fi

# Install fisher plugins
bash "$SETUP_DIR/core/fish/install-plugins.sh"
