#!/bin/bash
# Verification script to test devpod installation
# This script checks that the installation completed successfully

set -e

echo "╔══════════════════════════════════════════════════╗"
echo "║  DevPod Installation Verification               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++)) || true
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++)) || true
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check if Fish shell is installed
echo "Testing Fish shell installation..."
if command -v fish &> /dev/null; then
    FISH_VERSION=$(fish --version 2>&1)
    pass "Fish shell installed: $FISH_VERSION"
else
    fail "Fish shell not found"
fi
echo ""

# Test 2: Check if devbox is installed
echo "Testing devbox installation..."
if command -v devbox &> /dev/null; then
    DEVBOX_VERSION=$(devbox version 2>&1)
    pass "Devbox installed: $DEVBOX_VERSION"
else
    fail "Devbox not found"
fi
echo ""

# Test 3: Fish shell integration test - can Fish start without errors?
echo "Testing Fish shell integration..."
FISH_TEST=$(fish -c 'echo "Fish shell test successful"' 2>&1)
FISH_EXIT_CODE=$?

if [ $FISH_EXIT_CODE -eq 0 ]; then
    pass "Fish shell starts without errors"
else
    fail "Fish shell has errors on startup"
    echo "  Error output: $FISH_TEST"
fi
echo ""

# Test 4: Check devbox PATH is set in Fish
echo "Testing devbox PATH integration in Fish..."
DEVBOX_PATH_TEST=$(fish -c 'if test -n "$DEVBOX_PACKAGES_DIR"; echo "DEVBOX_PATH_SET"; else; echo "DEVBOX_PATH_NOT_SET"; end' 2>&1 | grep -v "Warning:")

if echo "$DEVBOX_PATH_TEST" | grep -q "DEVBOX_PATH_SET"; then
    DEVBOX_PACKAGES_DIR=$(fish -c 'echo $DEVBOX_PACKAGES_DIR' 2>&1 | grep -v "Warning:")
    pass "Devbox PATH is set in Fish: $DEVBOX_PACKAGES_DIR"
else
    fail "Devbox PATH not set in Fish environment"
fi
echo ""

# Test 5: Check if devbox packages are accessible in Fish
echo "Testing devbox package accessibility in Fish..."
# Test a few key packages to ensure PATH is working
TEST_COMMANDS=("fzf" "nvim" "lazygit" "rg" "bat")
ACCESSIBLE_COUNT=0

for cmd in "${TEST_COMMANDS[@]}"; do
    if fish -c "type -q $cmd" 2>/dev/null; then
        ((ACCESSIBLE_COUNT++)) || true
    fi
done

if [ $ACCESSIBLE_COUNT -eq ${#TEST_COMMANDS[@]} ]; then
    pass "All sample devbox packages accessible in Fish ($ACCESSIBLE_COUNT/${#TEST_COMMANDS[@]})"
else
    fail "Some devbox packages not accessible in Fish ($ACCESSIBLE_COUNT/${#TEST_COMMANDS[@]})"
fi
echo ""

# Test 6: Configuration files test
echo "Testing configuration files..."

# Check if Fish config directory exists
if [ -d "$HOME/.config/fish" ]; then
    pass "Fish config directory exists"
else
    fail "Fish config directory not found"
fi

# Check if devbox.fish exists
if [ -f "$HOME/.config/fish/conf.d/devbox.fish" ]; then
    pass "Devbox Fish integration file exists"
else
    fail "Devbox Fish integration file not found"
fi

# Check if Neovim config directory exists
if [ -d "$HOME/.config/nvim" ]; then
    pass "Neovim config directory exists"
else
    warn "Neovim config directory not found (expected if setup_neovim_config wasn't run)"
fi
echo ""

# Test 7: Check if stow created symlinks correctly
echo "Testing stow symlinks..."
if [ -L "$HOME/.config/fish/config.fish" ]; then
    pass "Fish config.fish is symlinked"
elif [ -f "$HOME/.config/fish/config.fish" ]; then
    # Check if the content matches the source (happens with --adopt)
    if [ -f "$HOME/dotfiles/.config/fish/config.fish" ]; then
        pass "Fish config.fish exists (adopted by stow)"
    else
        warn "Fish config.fish exists but is not a symlink and source not in dotfiles"
    fi
else
    fail "Fish config.fish not found"
fi
echo ""

# Test 8: Check SHELL variable in Fish
echo "Testing SHELL variable in Fish..."
SHELL_VAR=$(fish -c 'echo $SHELL' 2>&1)
if echo "$SHELL_VAR" | grep -q "fish"; then
    pass "SHELL variable is set to fish in Fish environment"
else
    warn "SHELL variable not set to fish (value: $SHELL_VAR)"
fi
echo ""

# Test 9: Check for common Fish startup errors
echo "Testing for common Fish startup errors..."
FISH_STARTUP=$(fish -c 'echo "startup_ok"' 2>&1)

if echo "$FISH_STARTUP" | grep -q "Missing end"; then
    fail "Fish has 'Missing end' syntax errors"
elif echo "$FISH_STARTUP" | grep -q "Unknown command"; then
    fail "Fish has 'Unknown command' errors"
elif echo "$FISH_STARTUP" | grep -q "startup_ok"; then
    pass "No common Fish startup errors detected"
else
    warn "Unexpected Fish startup output"
fi
echo ""

# Summary
echo "╔══════════════════════════════════════════════════╗"
echo "║  Verification Summary                            ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Tests passed: $PASS"
echo "Tests failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Installation is successful.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
    exit 1
fi
