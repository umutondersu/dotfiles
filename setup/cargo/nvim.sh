#!/bin/bash

./setup/nvim_deps.sh
cargo install --git https://github.com/MordechaiHadad/bob.git
bob use 0.10.1
export PATH=$HOME/.local/share/bob/nvim-bin:$PATH
