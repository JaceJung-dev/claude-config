#!/usr/bin/env bash
# Install all third-party content for this machine from the repo manifests:
#   skills  (npx skills)    <- library/skill-lock.json
#   plugins (claude plugin) <- library/plugin-lock.json
# Thin wrapper over install-skills.sh + install-plugins.sh. Individual scripts
# remain usable on their own. Pass --dry-run to preview without installing.
# Usage: install.sh [--dry-run]
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "########## skills ##########"
"$BIN/install-skills.sh" "$@"
echo
echo "########## plugins ##########"
"$BIN/install-plugins.sh" "$@"
