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

# Filter out packages that are already installed
packages_to_install=()
for pkg in "${packages[@]}"; do
    # Extract the package name (before @ if version is specified)
    pkg_name="${pkg%%@*}"
    
    if command -v "$pkg_name" &> /dev/null; then
        echo "$pkg_name is already installed, skipping..."
    else
        echo "$pkg_name will be installed"
        packages_to_install+=("$pkg")
    fi
done

# Install packages if any are needed
if [ ${#packages_to_install[@]} -gt 0 ]; then
    echo "Installing packages: ${packages_to_install[*]}"
    devbox global add "${packages_to_install[@]}"
else
    echo "All packages are already installed"
fi
