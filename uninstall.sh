#!/bin/bash
#
# uninstall.sh - stop and remove the drainwatch launchd agent and scripts.
#
set -euo pipefail

BIN="$HOME/.local/bin"
AGENT="$HOME/Library/LaunchAgents"
LABEL="com.prakharrr.drainwatch"
UID_N="$(id -u)"

launchctl bootout "gui/$UID_N/$LABEL" 2>/dev/null || true

rm -f "$AGENT/$LABEL.plist"
rm -f "$BIN/drainwatch.sh" "$BIN/drainwatch-kill"

echo "Uninstalled. Logs/state left in:"
echo "  $HOME/Library/Logs/drainwatch.log"
echo "  $HOME/Library/Application Support/drainwatch/"
