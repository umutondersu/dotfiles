#!/bin/bash

# Usage: ./run.sh <command>
# Example: ./run.sh playpause

COMMANDS_DIR="$HOME/.scripts/foobar/commands"
AVAILABLE=$(ls "$COMMANDS_DIR"/*.sh 2>/dev/null | xargs -I{} basename {} .sh | tr '\n' ' ')

if [ "$1" = "" ]; then
    echo "Usage: $0 <command>"
    echo "Available: $AVAILABLE"
    exit 1
fi

# Only run if foobar2000 is already open
if ! pgrep -i "foobar2000" > /dev/null 2>&1; then
    echo "Foobar2000 is not running!"
    exit 0
fi

SCRIPT="$COMMANDS_DIR/$1.sh"

if [ ! -f "$SCRIPT" ]; then
    echo "Unknown command: $1"
    echo "Available: $AVAILABLE"
    exit 1
fi

# Load prefix
export WINEPREFIX="$HOME/.local/share/wineprefixes/foobar"

# Run the target script
sh "$SCRIPT"
