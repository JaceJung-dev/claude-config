#!/usr/bin/env bash
# Capture current machine state into the repo manifests:
#   skills  -> library/skill-lock.json
#   plugins -> library/plugin-lock.json
# Thin wrapper over sync-skills.sh + sync-plugins.sh. Review & commit the diffs after.
# Usage: sync.sh
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "########## skills ##########"
"$BIN/sync-skills.sh"
echo
echo "########## plugins ##########"
"$BIN/sync-plugins.sh"
