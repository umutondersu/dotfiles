#!/usr/bin/env bash
# toggle-mic.sh - toggles the default microphone mute state on PipeWire

# Get the default source name
DEFAULT_SOURCE=$(pactl info | grep "Default Source" | awk '{print $3}')

if [ -z "$DEFAULT_SOURCE" ]; then
    echo "No default microphone found!"
    exit 1
fi

# Get current mute state (0 = unmuted, 1 = muted)
MUTE_STATE=$(pactl get-source-mute "$DEFAULT_SOURCE" | awk '{print $2}')

# Toggle mute
if [ "$MUTE_STATE" = "no" ]; then
    pactl set-source-mute "$DEFAULT_SOURCE" 1
    echo "Microphone muted"
else
    pactl set-source-mute "$DEFAULT_SOURCE" 0
    echo "Microphone unmuted"
fi
