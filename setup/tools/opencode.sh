#!/bin/bash

# Check if OpenCode is already installed
if command -v opencode &> /dev/null; then
    echo "✅ OpenCode is already installed: $(opencode --version 2>/dev/null || echo 'version unknown')"
    exit 0
fi

echo "Installing OpenCode..."
curl -fsSL https://opencode.ai/install | bash
