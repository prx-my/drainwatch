#!/bin/bash
#
# install.sh - install drainwatch into the current user's account.
# Copies the scripts to ~/.local/bin and loads the launchd agent.
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
AGENT="$HOME/Library/LaunchAgents"
LABEL="com.prakharrr.drainwatch"
UID_N="$(id -u)"

mkdir -p "$BIN" "$AGENT"

cp "$HERE/drainwatch.sh" "$BIN/drainwatch.sh"
cp "$HERE/drainwatch-kill" "$BIN/drainwatch-kill"
chmod +x "$BIN/drainwatch.sh" "$BIN/drainwatch-kill"

sed "s#/Users/prakharrr#$HOME#g" "$HERE/$LABEL.plist" > "$AGENT/$LABEL.plist"

launchctl bootout "gui/$UID_N/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_N" "$AGENT/$LABEL.plist"

echo "Installed."
echo "  scripts: $BIN/drainwatch.sh, $BIN/drainwatch-kill"
echo "  agent:   $AGENT/$LABEL.plist"
launchctl print "gui/$UID_N/$LABEL" 2>/dev/null | grep -E "state =|run interval" || true
echo "Add $BIN to your PATH if it isn't already."
