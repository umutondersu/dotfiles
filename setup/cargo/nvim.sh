#!/bin/bash

sudo apt install python3.11-venv -y
sudo apt install gcc -y
cargo install --git https://github.com/MordechaiHadad/bob.git
bob use 0.10.1
export PATH=$HOME/.local/share/bob/nvim-bin:$PATH


