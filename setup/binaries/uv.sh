#!/bin/bash

curl -LsSf https://astral.sh/uv/install.sh | sh

export PATH="$HOME/.local/bin:$PATH"

uv python install --default --preview 3.10

# Install Tools
uv tool install --python 3.12 posting
uv tool install thefuck --python=python3.11
uv tool install tldr

