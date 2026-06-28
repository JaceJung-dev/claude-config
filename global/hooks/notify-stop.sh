#!/bin/bash
session_id=$(/usr/bin/python3 -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)
[ -z "$session_id" ] && exit 0

start_file="/tmp/claude-notify-start-${session_id}"
[ ! -f "$start_file" ] && exit 0

start=$(cat "$start_file")
elapsed=$(($(date +%s) - start))
rm -f "$start_file"

if [ "$elapsed" -ge 60 ]; then
  osascript -e 'display notification "Task completed" with title "Claude Code" sound name "Glass"' &
fi
exit 0
