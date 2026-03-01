#!/bin/bash

export PATH="$HOME/.local/bin:$PATH" && distrobox enter wooting-container -- bash -c "cd ~/Applications && ./Wooting.Background.Service_0.4.7_amd64.AppImage"
