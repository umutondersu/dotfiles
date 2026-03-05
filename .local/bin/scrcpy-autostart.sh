#!/bin/bash
# Launched by udev via systemd-run --user when an Android phone is plugged in.
# Waits for ADB authorisation, then launches scrcpy.

ADB=/usr/bin/adb
SCRCPY=/usr/local/bin/scrcpy

# Wait up to 30 s for the device to be authorised
for i in $(seq 1 15); do
    if $ADB devices 2>/dev/null | grep -q $'^\S\+\tdevice$'; then
        break
    fi
    sleep 2
done

if ! $ADB devices 2>/dev/null | grep -q $'^\S\+\tdevice$'; then
    echo "Device not ready after timeout, aborting"
    exit 1
fi

exec $SCRCPY --turn-screen-off --stay-awake
