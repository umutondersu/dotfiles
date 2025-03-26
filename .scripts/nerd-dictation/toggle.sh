#!/bin/bash

# Check if nerd-dictation is already running
if pgrep -f "nerd-dictation begin" > /dev/null; then
    # If running, stop it
    echo "Stopping nerd-dictation..."
    python3 $HOME/.config/nerd-dictation/nerd-dictation end
    echo "Dictation stopped."
else
    # If not running, start it
    echo "Starting nerd-dictation..."
    python3 $HOME/.config/nerd-dictation/nerd-dictation begin
    echo "Dictation started."
fi
