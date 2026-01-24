#!/bin/bash

#NOTE: Make sure foo_runcmd component is installed in foobar2000
# CTRL+ALT+r
FOOBAR_PATH="$HOME/foobar2000/foobar2000.exe"
STATE_FILE="$HOME/.foobar_shuffle_state"

# Check if the state file exists and read its content
if [ -f "$STATE_FILE" ]; then
    STATE=$(cat "$STATE_FILE")
else
    STATE="off"
fi

# Toggle shuffle playback based on the current state
if [ "$STATE" = "off" ]; then
    wine "$FOOBAR_PATH" /runcmd="Playback/Order/Shuffle (tracks)"
    echo "on" > "$STATE_FILE"
else
    wine "$FOOBAR_PATH" /runcmd="Playback/Order/Default"
    echo "off" > "$STATE_FILE"
fi
