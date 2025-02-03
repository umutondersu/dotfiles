#!/bin/bash

./setup/nvim_deps.sh
cargo install fd-find
cargo install --git https://github.com/MordechaiHadad/bob.git
bob install latest
bob use latest
export PATH=$HOME/.local/share/bob/nvim-bin:$PATH
