#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Android Screen
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📱
# @raycast.packageName Mobile Tools

export PATH=$PATH:/opt/homebrew/bin:/usr/local/bin:$HOME/.local/share/devbox/global/default/.devbox/nix/profile/default/bin
scrcpy -S -w
