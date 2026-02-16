#!/bin/bash
# Wrapper script for development environment installation
# This is kept for backward compatibility and convenience

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running development environment installation (using install.sh --devenv)..."
echo ""

exec "$SCRIPT_DIR/install.sh" --devenv
