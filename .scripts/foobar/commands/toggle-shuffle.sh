#!/bin/bash

#NOTE: Make sure foo_runcmd component is installed in foobar2000
# CTRL+ALT+r
FOOBAR_PATH="$HOME/foobar2000/foobar2000.exe"
STATE_FILE="$HOME/.foobar_shuffle_state"
DB="$HOME/foobar2000/profile/config.sqlite"

# NULL GUID of foobar's "Default" playback order (all others mean shuffling)
DEFAULT_ORDER_GUID="BFC61179-49AD-4E95-8D60-A22706485505"

# foobar lives in this dedicated prefix; required when called outside run.sh
export WINEPREFIX="${WINEPREFIX:-$HOME/.local/share/wineprefixes/foobar}"

# Generation = pid:starttime of the running foobar instance ("none" if not running)
generation() {
    local pid starttime
    pid=$(pgrep -x "foobar2000.exe" | head -n1)
    if [ -z "$pid" ]; then
        echo "none"
        return
    fi
    starttime=$(awk '{print $22}' "/proc/$pid/stat" 2>/dev/null)
    echo "$pid:$starttime"
}

# foobar's own persisted playback order GUID (config is written on shutdown)
current_order_id() {
    sqlite3 -cmd ".timeout 500" "$DB" \
        "SELECT value FROM configStrings WHERE name='core.playbackOrderID';" 2>/dev/null
}

GEN="$(generation)"

# Load cached state and the generation it was recorded for
if [ -f "$STATE_FILE" ]; then
    CACHED_GEN=$(head -n1 "$STATE_FILE")
    CACHED_STATE=$(tail -n1 "$STATE_FILE")
else
    CACHED_GEN=""
    CACHED_STATE=""
fi

# Resync from foobar's own config when the cache is missing or foobar restarted
if [ -z "$CACHED_STATE" ] || [ "$CACHED_GEN" != "$GEN" ]; then
    ORDER_ID="$(current_order_id)"
    if [ -z "$ORDER_ID" ] && [ -n "$CACHED_STATE" ]; then
        STATE="$CACHED_STATE"
    elif [ "$ORDER_ID" = "$DEFAULT_ORDER_GUID" ]; then
        STATE="off"
    else
        STATE="on"
    fi
else
    STATE="$CACHED_STATE"
fi

# Toggle shuffle based on foobar's actual state
if [ "$STATE" = "off" ]; then
    wine "$FOOBAR_PATH" /runcmd="Playback/Order/Shuffle (tracks)"
    RC=$?
    NEW_STATE="on"
else
    wine "$FOOBAR_PATH" /runcmd="Playback/Order/Default"
    RC=$?
    NEW_STATE="off"
fi

# Record the new state only if the command was actually delivered to foobar
if [ "$RC" -eq 0 ]; then
    printf '%s\n%s\n' "$GEN" "$NEW_STATE" > "$STATE_FILE"
fi