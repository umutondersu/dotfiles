#!/bin/bash

curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env"

for script in ./setup/cargo/*.sh; do
  bash "$script"
done
