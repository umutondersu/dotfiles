#!/bin/bash

curl -LsSf https://astral.sh/uv/install.sh | sh

export PATH="$HOME/.local/bin:$PATH"

uv python install --default --preview 3.10

# install Posting (will also quickly install Python 3.12 if needed)
uv tool install --python 3.12 posting

