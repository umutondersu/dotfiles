#!/bin/bash

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run|-n]"
            exit 1
            ;;
    esac
done

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$DOTFILES_ROOT/desktop-packages.txt"

# Check if packages file exists
if [ ! -f "$PACKAGES_FILE" ]; then
    echo "Error: Package list not found at $PACKAGES_FILE"
    exit 1
fi

# Read packages from file, skipping comments and empty lines
packages=()
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    # Trim whitespace and add to array
    packages+=("$(echo "$line" | xargs)")
done < "$PACKAGES_FILE"

if [ ${#packages[@]} -eq 0 ]; then
    echo "No packages found in $PACKAGES_FILE"
    exit 0
fi

# Get the devbox global config path
devbox_config="$HOME/.local/share/devbox/global/default/devbox.json"

# Filter out packages that are already in devbox.json
packages_to_install=()
for pkg in "${packages[@]}"; do
    # Extract the package name (before @ if version is specified)
    pkg_name="${pkg%%@*}"
    
    # Check if package is in devbox.json (with any version)
    if grep -q "\"$pkg_name@" "$devbox_config" 2>/dev/null; then
        echo "✓ $pkg_name is already in devbox.json, skipping..."
    else
        echo "→ $pkg will be added"
        packages_to_install+=("$pkg")
    fi
done

# Install packages if any are needed
if [ ${#packages_to_install[@]} -gt 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        echo ""
        echo "[DRY RUN] Would install ${#packages_to_install[@]} packages:"
        for pkg in "${packages_to_install[@]}"; do
            echo "  - $pkg"
        done
        echo ""
        echo "[DRY RUN] Command: devbox global add ${packages_to_install[*]}"
    else
        echo ""
        echo "Installing ${#packages_to_install[@]} packages: ${packages_to_install[*]}"
        devbox global add "${packages_to_install[@]}"
    fi
else
    echo ""
    echo "✓ All packages are already in devbox.json"
fi
