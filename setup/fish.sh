#!/bin/bash
set -e

# Check if Fish is already installed
if command -v fish &> /dev/null; then
    FISH_VERSION=$(fish --version 2>/dev/null | grep -oP 'fish, version \K[0-9]+\.[0-9]+' || echo "unknown")
    echo "✅ Fish shell is already installed: $(fish --version)"
    
    # Check if version is 4.4.x
    if [[ "$FISH_VERSION" != "unknown" ]]; then
        MAJOR=$(echo "$FISH_VERSION" | cut -d'.' -f1)
        MINOR=$(echo "$FISH_VERSION" | cut -d'.' -f2)
        
        if [[ "$MAJOR" != "4" ]] || [[ "$MINOR" != "4" ]]; then
            echo ""
            echo "⚠️  WARNING: This dotfiles configuration is designed for Fish 4.4.x"
            echo "   Your version: $FISH_VERSION"
            echo "   Some features might not function properly with this version."
            echo "   Consider upgrading to Fish 4.4.x for the best experience."
            echo ""
        fi
    fi
    
    exit 0
fi

echo "Installing Fish shell..."

# Check the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot determine distribution"
    exit 1
fi

# Install Fish shell based on distribution
case $DISTRO in
    ubuntu|pop)
        # Ubuntu/Pop!_OS installation using PPA
        echo "  Detected Ubuntu/Pop!_OS, installing from PPA..."
        sudo apt install -y software-properties-common
        sudo apt-add-repository -y ppa:fish-shell/release-4
        sudo apt update
        sudo apt install -y fish
        ;;
    debian)
        # Get Debian version
        if [ -f /etc/debian_version ]; then
            DEBIAN_VERSION=$(cut -d'.' -f1 < /etc/debian_version)
            if [[ $VERSION_CODENAME == "sid" ]]; then
                DEBIAN_RELEASE="Unstable"
            elif [ "$DEBIAN_VERSION" = "12" ]; then
                DEBIAN_RELEASE="12"
            elif [ "$DEBIAN_VERSION" = "11" ]; then
                DEBIAN_RELEASE="11"
            else
                echo "❌ Unsupported Debian version"
                exit 1
            fi
            
            # Debian installation from official repositories
            echo "  Detected Debian ${DEBIAN_RELEASE}, installing from OBS repository..."
            echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${DEBIAN_RELEASE}/ /" | \
                sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
            curl -fsSL "https://download.opensuse.org/repositories/shells:fish:release:4/Debian_${DEBIAN_RELEASE}/Release.key" | \
                gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
            sudo apt update
            sudo apt install -y fish
        else
            echo "❌ Cannot determine Debian version"
            exit 1
        fi
        ;;
    *)
        echo "❌ Unsupported distribution: $DISTRO"
        echo "Please install Fish manually from: https://fishshell.com/"
        exit 1
        ;;
esac

echo "✅ Fish shell installed: $(fish --version)"
