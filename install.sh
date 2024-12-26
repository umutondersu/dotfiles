#!/bin/bash

./setup/stow.sh
./setup/binaries.sh
./setup/cargo.sh
./setup/fish.sh

git clone https://github.com/umutondersu/nvim.git ~/.config/nvim
sudo chsh -s /usr/bin/fish $USER

./setup/tmux.sh
