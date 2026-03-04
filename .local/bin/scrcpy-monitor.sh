#!/bin/bash
# scrcpy-monitor: watches for a udev trigger file and launches scrcpy once per plug event.
# Runs as a systemd user service so it has full access to the X11 display.

TRIGGER_FILE="/run/user/$(id -u)/scrcpy-trigger"
SCRCPY=/usr/local/bin/scrcpy
ADB=/usr/bin/adb
SCRCPY_PID=""

is_scrcpy_running() {
    [ -n "$SCRCPY_PID" ] && kill -0 "$SCRCPY_PID" 2>/dev/null
}

launch_scrcpy() {
    # Wait for ADB to authorise the device (up to 30 s)
    for i in $(seq 1 15); do
        if $ADB devices 2>/dev/null | grep -q $'^\S\+\tdevice$'; then
            break
        fi
        sleep 2
    done

    if ! $ADB devices 2>/dev/null | grep -q $'^\S\+\tdevice$'; then
        echo "Device not ready after timeout, skipping launch"
        return
    fi

    echo "Device connected – launching scrcpy"
    $SCRCPY --turn-screen-off --stay-awake &
    SCRCPY_PID=$!
}

trap 'kill "$SCRCPY_PID" 2>/dev/null; exit 0' SIGTERM SIGINT

echo "scrcpy-monitor started, watching for $TRIGGER_FILE"

# Remove any stale trigger from a previous session
rm -f "$TRIGGER_FILE"

while true; do
    # Block until the trigger file appears (inotifywait) or fall back to polling
    if command -v inotifywait >/dev/null 2>&1; then
        inotifywait -qq -e create -e moved_to "$(dirname "$TRIGGER_FILE")" \
            --include "$(basename "$TRIGGER_FILE")" 2>/dev/null
    else
        while [ ! -f "$TRIGGER_FILE" ]; do sleep 1; done
    fi

    if [ -f "$TRIGGER_FILE" ]; then
        rm -f "$TRIGGER_FILE"
        if is_scrcpy_running; then
            echo "scrcpy already running, ignoring trigger"
        else
            launch_scrcpy
        fi
    fi
done
