#!/usr/bin/env bash
# One-command machine setup from this repo. Run after cloning on a fresh machine:
#   1. deploy-global.sh -> symlink global config (CLAUDE.md, settings, commands,
#                          hooks, statusline) into ~/.claude
#   2. install.sh       -> install skills + plugins from the repo manifests
# Pass --dry-run to preview every step without changing anything.
# Usage: bootstrap.sh [--dry-run]
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========== 1/2 deploy-global =========="
"$BIN/deploy-global.sh" "$@"
echo
echo "========== 2/2 install (skills + plugins) =========="
"$BIN/install.sh" "$@"
echo
echo "bootstrap done. (review: git -C \"$(dirname "$BIN")\" status)"
