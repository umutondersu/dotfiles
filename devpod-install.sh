#!/bin/bash

./setup/stow.sh
./setup/fish.sh
./setup/binaries.sh
./setup/wo_cargo.sh
./setup/npm_binaries.sh

git clone https://github.com/umutondersu/nvim.git ~/.config/nvim
sudo chsh -s /usr/bin/fish $USER

mkdir -p ~/.gnupg
echo "use-standard-socket" > ~/.gnupg/gpg-agent.conf
