#!/bin/bash

./setup/stow.sh
./setup/fish.sh
./setup/binaries.sh
./setup/cargo.sh
./setup/npm_binaries.sh

git clone https://github.com/umutondersu/nvim.git ~/.config/nvim
sudo chsh -s /usr/bin/fish "$USER"

./setup/tmux.sh
./setup/nerd-dictation.sh
