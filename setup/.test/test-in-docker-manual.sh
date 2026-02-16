#!/bin/bash
# Manual Docker test - starts a container where you can run the installation yourself
# Usage: ./test-in-docker-manual.sh

set -e

# Get the absolute path to dotfiles (go up two directories from setup/.test)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "╔══════════════════════════════════════════════════╗"
echo "║  Manual Docker Testing Environment              ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Starting Ubuntu 22.04 container with your dotfiles mounted..."
echo "Dotfiles location: $DOTFILES_DIR"
echo ""
echo "Once inside the container, run:"
echo "  1. apt-get update && apt-get install -y git curl sudo"
echo "  2. cp -r /dotfiles /root/dotfiles"
echo "  3. cd /root/dotfiles"
echo "  4. ./install.sh  (dev environment mode by default)"
echo "  5. ./setup/.test/verify-installation.sh  (optional: verify installation)"
echo ""
echo "Then test your packages: nvim, fish, lazygit, fzf, etc."
echo ""
echo "Tip: For fully automated testing, use ./test-in-docker-automated.sh instead"
echo ""
echo "Type 'exit' when done to remove the container."
echo ""
echo "Starting container..."
echo ""

docker run -it --rm \
  -v "$DOTFILES_DIR:/dotfiles:ro" \
  ubuntu:22.04 \
  bash
