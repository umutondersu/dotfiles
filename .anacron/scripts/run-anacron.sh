#!/bin/bash
# Runner script for user anacron
# This should be called from cron or at system startup

ANACRON_DIR="$HOME/.anacron"
ANACRONTAB="$ANACRON_DIR/etc/anacrontab"
SPOOL_DIR="$ANACRON_DIR/spool"

# Ensure spool directory exists
mkdir -p "$SPOOL_DIR"

# Run anacron with user configuration
/usr/bin/anacron -t "$ANACRONTAB" -S "$SPOOL_DIR"
