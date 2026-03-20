#!/bin/bash
# Foobar2000 Profile Daily Backup Script
# Automatically commits and pushes changes to GitHub

PROFILE_DIR="/home/qorcialwolf/foobar2000/profile"
LOG_FILE="$HOME/.anacron/logs/foobar-backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Use plaintext GCM credential store for headless operation
# (avoids secretservice/D-Bus dependency without affecting global git config)
export GCM_CREDENTIAL_STORE=plaintext

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Redirect all output to log file
exec >> "$LOG_FILE" 2>&1

echo "=========================================="
echo "Backup started: $DATE"
echo "=========================================="

# Change to profile directory
cd "$PROFILE_DIR" || {
    echo "ERROR: Could not change to profile directory"
    exit 1
}

# Check if there are any changes
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "No changes detected. Skipping backup."
    exit 0
fi

# Add all tracked files that have been modified
echo "Adding modified files..."
git add -u

# Add new files (excluding those in .gitignore)
echo "Checking for new files..."
NEW_FILES=$(git ls-files --others --exclude-standard)
if [ -n "$NEW_FILES" ]; then
    echo "Found new files:"
    echo "$NEW_FILES"
    git add .
fi

# Check if there are changes to commit after staging
if git diff --cached --quiet; then
    echo "No changes to commit after staging."
    exit 0
fi

# Detect OS for commit message label
if grep -qi "cachyos" /etc/os-release 2>/dev/null; then
    OS_LABEL="cachyos"
elif grep -qi "pop" /etc/os-release 2>/dev/null; then
    OS_LABEL="popos"
else
    OS_LABEL="unknown"
fi

# Create commit with timestamp
COMMIT_MSG="Auto-backup ($OS_LABEL): $(date '+%Y-%m-%d %H:%M')"
echo "Creating commit: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

# Push to remote
echo "Pushing to GitHub..."
if git push origin main; then
    echo "✓ Backup successful!"
else
    echo "✗ ERROR: Failed to push to GitHub"
    echo "  Check your network connection and GitHub authentication"
    exit 1
fi

echo "Backup completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
