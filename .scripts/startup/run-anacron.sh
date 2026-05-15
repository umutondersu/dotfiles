#!/bin/bash
# Run user anacron on startup.

ANACRON_DIR="$HOME/.anacron"
ANACRONTAB="$ANACRON_DIR/etc/anacrontab"
SPOOL_DIR="$ANACRON_DIR/spool"

mkdir -p "$SPOOL_DIR"

anacron -t "$ANACRONTAB" -S "$SPOOL_DIR"
