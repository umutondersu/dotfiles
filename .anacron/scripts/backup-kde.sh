#!/bin/bash
# KDE Profile Weekly Backup Script
# Exports KDE settings via konsave and moves the archive to the T7 drive

LOG_FILE="$HOME/.anacron/logs/kde-backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Redirect all output to log file
exec >> "$LOG_FILE" 2>&1

echo "=========================================="
echo "Backup started: $DATE"
echo "=========================================="

# Guard: konsave must be executable
if ! command -v konsave &>/dev/null; then
    echo "ERROR: konsave not found in PATH. Aborting."
    exit 1
fi

# Dynamically find the T7 mount by filesystem label
MOUNT=$(findmnt -rn -o TARGET LABEL=T7 2>/dev/null)
if [ -z "$MOUNT" ]; then
    echo "ERROR: T7 drive not mounted (label 'T7' not found). Aborting."
    exit 1
fi

BACKUP_DIR="$MOUNT/Backup/kde"
mkdir -p "$BACKUP_DIR" || {
    echo "ERROR: Could not create backup directory: $BACKUP_DIR"
    exit 1
}

# Export from $HOME so the .knsv file lands at ~/my-setup.knsv
cd "$HOME" || {
    echo "ERROR: Could not cd to HOME directory"
    exit 1
}

echo "Exporting KDE profile via konsave..."
if konsave -e my-setup -f; then
    echo "Export successful."
else
    echo "ERROR: konsave export failed."
    exit 1
fi

DEST="$BACKUP_DIR/my-setup-$(date +%Y%m%d).knsv"
echo "Moving archive to: $DEST"
if mv ./my-setup.knsv "$DEST"; then
    echo "Backup completed successfully: $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "ERROR: Failed to move archive to $DEST"
    exit 1
fi

echo ""
