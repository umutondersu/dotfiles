#!/bin/bash
# Foobar2000 Profile Daily Backup Script (Secondary PC)
# Pulls latest from origin first (respecting skip-worktree files),
# then commits and pushes any local changes to GitHub.

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
echo "Backup started (secondary): $DATE"
echo "=========================================="

# Change to profile directory
cd "$PROFILE_DIR" || {
    echo "ERROR: Could not change to profile directory"
    exit 1
}

# Pull from origin, preserving skip-worktree files
echo "Pulling latest changes from origin..."
SKIP_FILES=()
while IFS= read -r line; do
    SKIP_FILES+=("${line:2}")  # strip leading "S " prefix
done < <(git ls-files -v | grep '^S')

if [ ${#SKIP_FILES[@]} -gt 0 ]; then
    echo "  Lifting skip-worktree on ${#SKIP_FILES[@]} file(s)..."
    for f in "${SKIP_FILES[@]}"; do
        git update-index --no-skip-worktree "$f"
    done
fi

if git fetch origin; then
    if git rebase origin/main; then
        echo "  Pull (rebase) successful."
    else
        echo "ERROR: Rebase failed. Aborting rebase and exiting."
        git rebase --abort 2>/dev/null
        # Re-apply skip-worktree before exiting
        for f in "${SKIP_FILES[@]}"; do
            [ -f "$f" ] && git update-index --skip-worktree "$f"
        done
        exit 1
    fi
else
    echo "ERROR: Could not fetch from origin. Check network connection."
    # Re-apply skip-worktree before exiting
    for f in "${SKIP_FILES[@]}"; do
        [ -f "$f" ] && git update-index --skip-worktree "$f"
    done
    exit 1
fi

# Re-apply skip-worktree flags
if [ ${#SKIP_FILES[@]} -gt 0 ]; then
    echo "  Re-applying skip-worktree on ${#SKIP_FILES[@]} file(s)..."
    for f in "${SKIP_FILES[@]}"; do
        if [ -f "$f" ]; then
            git update-index --skip-worktree "$f"
        fi
    done
fi

# Check if there are any local changes to back up
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "No local changes detected. Skipping commit."
    echo "Backup completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
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
    echo "Backup completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
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

# Push to remote with retry logic
echo "Pushing to GitHub..."
PUSH_SUCCESS=false
for attempt in 1 2 3; do
    if git push origin main; then
        PUSH_SUCCESS=true
        break
    else
        if [ $attempt -lt 3 ]; then
            echo "  Push attempt $attempt failed. Retrying in 30 seconds..."
            sleep 30
        fi
    fi
done

if $PUSH_SUCCESS; then
    echo "✓ Backup successful!"
else
    echo "✗ ERROR: Failed to push to GitHub after 3 attempts"
    echo "  Check your network connection and GitHub authentication"
    exit 1
fi

echo "Backup completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
