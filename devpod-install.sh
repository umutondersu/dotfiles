#!/bin/bash
#TODO: Neovim from devcontainer features has only 1 version. Can cause a conflict later
./setup/stow.sh
./setup/binaries.sh
./setup/wo_cargo.sh
./setup/fish.sh

git clone https://github.com/umutondersu/nvim.git ~/.config/nvim
sudo chsh -s /usr/bin/fish $USER

mkdir -p ~/.gnupg
echo "use-standard-socket" > ~/.gnupg/gpg-agent.conf
