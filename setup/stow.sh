#!/bin/bash

export XDG_CONFIG_HOME="$HOME"/.config
mkdir -p "$XDG_CONFIG_HOME"

sudo apt update
sudo apt install stow -y
cd $HOME/dotfiles
stow . --adopt
