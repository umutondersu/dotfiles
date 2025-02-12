#!/bin/bash

./setup/nvim_deps.sh
git clone -b v0.10.4 https://www.github.com/neovim/neovim.git $HOME/personal/neovim
sudo apt install -y cmake gettext lua5.1 liblua5.1-0-dev
cd $HOME/personal/neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
cd $HOME/dotfiles
