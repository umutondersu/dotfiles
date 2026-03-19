#!/bin/bash
# Install Fisher plugins from fish_plugins file

FISH_PLUGINS="$HOME/.config/fish/fish_plugins"

# Idempotency check: all plugins already installed if fisher_path is populated
FISHER_PATH="$HOME/.local/share/fisher"
if [ -d "$FISHER_PATH" ] && [ "$(ls -A "$FISHER_PATH" 2>/dev/null)" ]; then
    echo "✅ Fisher plugins already installed at $FISHER_PATH"
    exit 0
fi

if [ ! -f "$FISH_PLUGINS" ]; then
    echo "⚠️  fish_plugins not found at $FISH_PLUGINS (non-fatal)"
    exit 0
fi

if ! command -v fish &> /dev/null; then
    echo "⚠️  fish not found, skipping plugin install (non-fatal)"
    exit 0
fi

echo "🐟 Installing Fisher plugins..."
if fish -c "fisher install < $FISH_PLUGINS" 2>/dev/null; then
    echo "✅ Fisher plugins installed"
else
    echo "⚠️  Fisher plugin installation failed (non-fatal)"
    echo "   Run manually: fisher install < ~/.config/fish/fish_plugins"
    exit 0
fi
