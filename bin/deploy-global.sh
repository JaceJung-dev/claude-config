#!/usr/bin/env bash
# Deploy repo global/ config into ~/.claude via symlinks (idempotent).
# Usage: deploy-global.sh [--dry-run]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/global"
DEST="$HOME/.claude"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

link() {
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then echo "skip (no src): $src"; return; fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "backup: $dest -> $dest.bak"
    if [ "$DRY" = 0 ]; then mv "$dest" "$dest.bak"; fi
  fi
  echo "link: $dest -> $src"
  if [ "$DRY" = 0 ]; then ln -sfn "$src" "$dest"; fi
}

link "$SRC/CLAUDE.md"              "$DEST/CLAUDE.md"
link "$SRC/settings.json"          "$DEST/settings.json"
link "$SRC/statusline-command.sh"  "$DEST/statusline-command.sh"
link "$SRC/hooks/quality-check.sh" "$DEST/hooks/quality-check.sh"
for h in "$SRC"/hooks/notify-*.sh; do
  [ -e "$h" ] && link "$h" "$DEST/hooks/$(basename "$h")"
done
echo "done."
