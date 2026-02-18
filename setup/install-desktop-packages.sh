#!/bin/bash

# Define packages to install
packages=(
    "tmux@3.2a"
    "streamrip"
    "yt-dlp"
    "dysk"
    "sesh@2.20.0"
    "git-credential-manager"
)

# Get the devbox global config path
devbox_config="$HOME/.local/share/devbox/global/default/devbox.json"

# Filter out packages that are already in devbox.json
packages_to_install=()
for pkg in "${packages[@]}"; do
    # Extract the package name (before @ if version is specified)
    pkg_name="${pkg%%@*}"
    
    # Check if package is in devbox.json
    if grep -q "\"$pkg_name@" "$devbox_config" 2>/dev/null; then
        echo "$pkg_name is already in devbox.json, skipping..."
    else
        echo "$pkg_name will be added"
        packages_to_install+=("$pkg")
    fi
done

# Install packages if any are needed
if [ ${#packages_to_install[@]} -gt 0 ]; then
    echo "Installing packages: ${packages_to_install[*]}"
    devbox global add "${packages_to_install[@]}"
else
    echo "All packages are already in devbox.json"
fi
