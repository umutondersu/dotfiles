#!/usr/bin/env bash
# echo-nano-sync.sh
# Installs the privileged pieces for the Echo Nano auto-sync watcher:
#   1. /etc/sudoers.d/echo-nano-sync — passwordless fatsort/fsck.fat for the
#      headless auto-sync (sudoers files must be real root:root 0440 files, so
#      this is installed by copy, not stowed/symlinked).
#   2. Enables ~/.config/systemd/user/echo-nano-sync.service (stowed from dotfiles).
#
# Skips quietly if the sync tooling (~/bin/echo-nano-sync*) is not present yet.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUDOERS_SRC="$SCRIPT_DIR/echo-nano-sync.sudoers"
SUDOERS_DST="/etc/sudoers.d/echo-nano-sync"
SERVICE="echo-nano-sync.service"
SERVICE_DST="$HOME/.config/systemd/user/$SERVICE"

# Only run when the actual sync scripts exist (~/bin repo cloned)
if [ ! -x "$HOME/bin/echo-nano-sync" ] || [ ! -x "$HOME/bin/echo-nano-sync-watch" ]; then
    echo "⏭️  Skipping Echo Nano setup — ~/bin/echo-nano-sync not found. Clone the bin repo first."
    exit 0
fi

echo "🔒 Installing passwordless sudoers rule for fatsort/fsck.fat..."
sudo install -o root -g root -m 0440 "$SUDOERS_SRC" "$SUDOERS_DST"
sudo visudo -c

if [ ! -f "$SERVICE_DST" ]; then
    echo "⚠️  $SERVICE_DST not found (did stow run?). Re-run after stowing dotfiles."
    exit 0
fi

echo "🛠️  Enabling Echo Nano auto-sync user service..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE"

echo "✅ Echo Nano auto-sync setup complete."
