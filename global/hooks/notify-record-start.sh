#!/bin/bash
# Record task start time per session_id for Stop hook duration check.
session_id=$(/usr/bin/python3 -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)
[ -z "$session_id" ] && exit 0
echo "$(date +%s)" > "/tmp/claude-notify-start-${session_id}"
exit 0
