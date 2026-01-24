#!/bin/bash

# Usage: ./run.sh <command>
# Example: ./run.sh playpause

if [ "$1" = "" ]; then
    echo "Usage: $0 <script-name>"
    exit 1
fi

SCRIPT="$HOME/.scripts/foobar/commands/$1.sh"

if [ ! -f "$SCRIPT" ]; then
    echo "Script $SCRIPT not found!"
    exit 1
fi

# Load prefix
export WINEPREFIX="$HOME/.local/share/wineprefixes/foobar"

# Run the target script
sh "$SCRIPT"
