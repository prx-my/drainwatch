#!/bin/bash
#
# drainwatch.sh - detect processes pegging a CPU core and alert the user.
# Runs from a launchd LaunchAgent every INTERVAL seconds. Never kills anything.
#
# Tunables (override via env in the plist):
#   DRAINWATCH_THRESHOLD  CPU % a process must exceed            (default 80)
#   DRAINWATCH_SUSTAIN    seconds above threshold before alert   (default 600)
#
set -u
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

THRESHOLD=${DRAINWATCH_THRESHOLD:-80}
SUSTAIN=${DRAINWATCH_SUSTAIN:-600}

DIR="$HOME/Library/Application Support/drainwatch"
STATE="$DIR/state.tsv"
LOG="$HOME/Library/Logs/drainwatch.log"
mkdir -p "$DIR"
mkdir -p "$(dirname "$LOG")"
touch "$STATE" "$LOG"

now=$(date +%s)
ts=$(date '+%Y-%m-%d %H:%M:%S')

sample=$(mktemp)
newstate=$(mktemp)
: > "$newstate"

# instantaneous CPU sample; second `top` block is interval-based
top -l 2 -n 25 -o cpu -stats pid,command,cpu 2>/dev/null | awk '
  /^[[:space:]]*PID[[:space:]]+COMMAND/ { h++; next }
  h>=2 && $1 ~ /^[0-9]+$/ && $NF ~ /^[0-9.]+$/ {
    cmd=""; for (i=2;i<NF;i++) cmd=(i==2?$i:cmd" "$i);
    print $1"|"$NF"|"cmd
  }' > "$sample"

while IFS='|' read -r pid cpu cmd; do
  c=${cpu%.*}
  [ -z "$c" ] && continue
  [ "$c" -lt "$THRESHOLD" ] && continue

  prev=$(awk -F'|' -v p="$pid" '$1==p {print $2"|"$3; exit}' "$STATE")
  first=${prev%%|*}
  notif=${prev##*|}
  [ -z "$prev" ] && { first=""; notif=""; }
  [ -z "$first" ] && { first=$now; notif=0; }

  held=$(( now - first ))

  if [ "$notif" = "0" ] && [ "$held" -ge "$SUSTAIN" ]; then
    mins=$(( held / 60 ))
    fullname=$(ps -p "$pid" -o comm= 2>/dev/null)
    if [ -n "$fullname" ]; then name=$(basename "$fullname"); else name=$cmd; fi
    /usr/bin/osascript -e "display notification \"${name} (pid ${pid}) has used ~${c}% CPU for ${mins} min.\" with title \"DrainWatch: sustained high CPU\" subtitle \"Battery drain suspected\" sound name \"Ping\"" >/dev/null 2>&1
    echo "$ts  ALERT  pid=$pid  cpu=${c}%  held=${mins}m  name=$name" >> "$LOG"
    notif=1
  fi

  echo "$pid|$first|$notif|$cmd" >> "$newstate"
done < "$sample"

mv "$newstate" "$STATE"
rm -f "$sample"
