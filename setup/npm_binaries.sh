#!/bin/bash

# Ensure nvm is loaded
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Get the node version from fish
node_version=$(fish -c 'echo $nvm_default_version')

# Use the specific Node version
nvm use "$node_version" || nvm install "$node_version"

# Ensure npm is available
export PATH="$NVM_DIR/versions/node/$(nvm current)/bin:$PATH"

# Install npm packages
npm install -g tldr fish-lsp

# Only install fd-find if it's not already installed with cargo
if ! command -v fd &> /dev/null; then
  npm install -g fd-find
fi
