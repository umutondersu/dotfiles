#!/usr/bin/env bash
# Check and install devbox if needed

if command -v devbox &> /dev/null; then
    echo "✅ Devbox found: $(devbox version)"
    exit 0
fi

echo "📦 Devbox not found, installing..."
# Use -f flag to skip interactive prompts (required for non-TTY environments)
curl -fsSL https://get.jetify.com/devbox | bash -s -- -f

# Source the devbox environment
export PATH="$HOME/.local/bin:$PATH"

if ! command -v devbox &> /dev/null; then
    echo "❌ Error: Devbox installation failed"
    echo "Please install manually: https://www.jetify.com/devbox/docs/installing_devbox/"
    exit 1
fi

echo "✅ Devbox installed successfully: $(devbox version)"
