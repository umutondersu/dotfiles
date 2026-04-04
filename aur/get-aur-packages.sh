#!/bin/env bash

pacman -Qqe | while read pkg; do
  if pacman -Qi "$pkg" | grep -q 'Packager\s*: Unknown'; then
    echo "$pkg"
  fi
done
