#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLATPAK_LIST="$SCRIPT_DIR/../flatpak-apps.txt"

# Check if flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo "Warning: Flatpak is not installed on this system"
    echo "Skipping Flatpak application installation"
    return 0
fi

# Check if flatpak-apps.txt exists
if [ ! -f "$FLATPAK_LIST" ]; then
    echo "Error: flatpak-apps.txt not found at $FLATPAK_LIST"
    return 1
fi

# Ensure flathub remote is configured
if ! flatpak remotes | grep -q "flathub"; then
    echo "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Read apps from file, filter out comments and empty lines
mapfile -t all_apps < <(grep -v '^#' "$FLATPAK_LIST" | grep -v '^[[:space:]]*$')

if [ ${#all_apps[@]} -eq 0 ]; then
    echo "No applications found in flatpak-apps.txt"
    return 0
fi

echo "Found ${#all_apps[@]} applications in flatpak-apps.txt"
echo "Checking which apps are already installed..."

# Filter out already-installed apps
apps_to_install=()
for app in "${all_apps[@]}"; do
    if flatpak list --app --columns=application | grep -q "^${app}$"; then
        echo "  ✓ $app is already installed, skipping..."
    else
        apps_to_install+=("$app")
    fi
done

# If all apps are installed, exit early
if [ ${#apps_to_install[@]} -eq 0 ]; then
    echo ""
    echo "All applications are already installed"
    return 0
fi

# Show list of apps to be installed
echo ""
echo "The following ${#apps_to_install[@]} applications will be installed:"
for app in "${apps_to_install[@]}"; do
    echo "  • $app"
done
echo ""

# Prompt user for confirmation
read -p "Install these applications? [y/N]: " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Flatpak application installation"
    return 0
fi

# Install all apps at once
echo ""
echo "Installing Flatpak applications..."
echo ""

# Use flatpak install with all apps at once for better UX
if flatpak install -y flathub "${apps_to_install[@]}"; then
    echo ""
    echo "✅ Flatpak applications installed successfully"
else
    echo ""
    echo "⚠️  Some applications may have failed to install"
    echo "You can retry manually with: flatpak install flathub <app-id>"
    return 1
fi
