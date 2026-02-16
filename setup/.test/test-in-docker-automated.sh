#!/bin/bash
# Automated Docker test - runs installation and verification automatically
# Usage: ./test-in-docker-automated.sh

set -e

# Get the absolute path to dotfiles (go up two directories from setup/.test)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "╔══════════════════════════════════════════════════╗"
echo "║  Automated Docker Testing Environment           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "This script will:"
echo "  1. Start an Ubuntu 22.04 container"
echo "  2. Run install.sh (dev environment mode)"
echo "  3. Verify the installation"
echo "  4. Report results"
echo ""
echo "Dotfiles location: $DOTFILES_DIR"
echo ""
read -p "Press Enter to start the automated test..."
echo ""

# Create a temporary script to run inside the container
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Step 1: Installing prerequisites"
echo "=========================================="
apt-get update -qq
apt-get install -y git curl sudo

echo ""
echo "=========================================="
echo "Step 2: Copying dotfiles"
echo "=========================================="
cp -r /dotfiles /root/dotfiles
cd /root/dotfiles

echo ""
echo "=========================================="
echo "Step 3: Running install.sh (dev environment)"
echo "=========================================="
./install.sh

echo ""
echo "=========================================="
echo "Step 4: Running verification tests"
echo "=========================================="
./setup/.test/verify-installation.sh

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
EOF

chmod +x "$TEMP_SCRIPT"

# Run the container with the test script
echo "Starting Docker container and running tests..."
echo ""

docker run -i --rm \
  -v "$DOTFILES_DIR:/dotfiles:ro" \
  -v "$TEMP_SCRIPT:/test-script.sh:ro" \
  ubuntu:22.04 \
  /test-script.sh

TEST_EXIT_CODE=$?

# Cleanup
rm -f "$TEMP_SCRIPT"

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  ✓ All tests passed successfully!               ║"
    echo "╚══════════════════════════════════════════════════╝"
else
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  ✗ Some tests failed. Review output above.      ║"
    echo "╚══════════════════════════════════════════════════╝"
fi

exit $TEST_EXIT_CODE
