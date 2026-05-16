#!/usr/bin/env bash
# Check and install stow if needed

if command -v stow &> /dev/null; then
    echo "✅ Stow already installed"
    exit 0
fi

echo "📦 Stow not found, installing..."

detect_package_manager() {
    if command -v apt-get &> /dev/null; then echo "apt"
    elif command -v dnf &> /dev/null; then echo "dnf"
    elif command -v yum &> /dev/null; then echo "yum"
    elif command -v pacman &> /dev/null; then echo "pacman"
    elif command -v zypper &> /dev/null; then echo "zypper"
    elif command -v apk &> /dev/null; then echo "apk"
    else echo "unknown"
    fi
}

pkg_manager=$(detect_package_manager)

case $pkg_manager in
    apt)    sudo apt-get update -qq && sudo apt-get install -y stow ;;
    dnf)    sudo dnf install -y stow ;;
    yum)    sudo yum install -y stow ;;
    pacman) sudo pacman -Sy --noconfirm stow ;;
    zypper) sudo zypper install -y stow ;;
    apk)    sudo apk add --no-cache stow ;;
    *)
        echo "❌ Error: Could not detect package manager"
        echo "Please install stow manually: https://www.gnu.org/software/stow/"
        exit 1
        ;;
esac

if command -v stow &> /dev/null; then
    echo "✅ Stow installed successfully"
else
    echo "❌ Error: Stow installation failed with package manager $pkg_manager"
    exit 1
fi
