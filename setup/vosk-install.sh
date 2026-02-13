#!/bin/bash
set -e

echo "🔊 Installing vosk Python package..."

# Check if vosk is already installed
if python3 -c "import vosk" 2>/dev/null; then
    echo "✅ vosk already installed, skipping..."
    exit 0
fi

# Ensure Python and pip are available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 not found. Make sure devbox packages are installed."
    exit 1
fi

# Install vosk via pip
python3 -m pip install --user vosk

echo "✅ vosk installed successfully"
