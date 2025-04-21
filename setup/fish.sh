#!/bin/bash

# Check the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot determine distribution"
    exit 1
fi

# Install Fish shell based on distribution
case $DISTRO in
    ubuntu|pop)
        # Ubuntu/Pop!_OS installation using PPA
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
                echo "Unsupported Debian version"
                exit 1
            fi
            
            # Debian installation from official repositories
            echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_${DEBIAN_RELEASE}/ /" | \
                sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
            curl -fsSL "https://download.opensuse.org/repositories/shells:fish:release:4/Debian_${DEBIAN_RELEASE}/Release.key" | \
                gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
            sudo apt update
            sudo apt install -y fish
        else
            echo "Cannot determine Debian version"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

fish -c 'nvm install $nvm_default_version'
