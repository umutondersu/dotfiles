#!/bin/bash

if command -v python3 >/dev/null 2>&1 && (command -v pip3 >/dev/null 2>&1 || (sudo apt-get update && sudo apt-get install -y python3-pip)); then
    pip3 install thefuck --user
fi
