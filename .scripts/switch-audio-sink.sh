#!/bin/bash
mapfile -t sinks < <(pactl list short sinks | awk '{print $2}' | grep -v -i -E 'easyeffects|dualSense')

sink_current=$(pactl get-default-sink)

for i in "${!sinks[@]}"; do
  if [[ "${sinks[$i]}" == "$sink_current" ]]; then
    next=$(( (i + 1) % ${#sinks[@]} ))
    pactl set-default-sink "${sinks[$next]}"
    exit 0
  fi
done

# Current sink not in list; fall back to first
pactl set-default-sink "${sinks[0]}"
