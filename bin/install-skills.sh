#!/usr/bin/env bash
# Install/restore npx-managed third-party skills globally, derived from the lockfile.
# Single source of truth: library/skill-lock.json — add/remove skills via
# `npx skills add/remove -g` + bin/sync-skills.sh, and this script follows automatically.
# Note: installs the LATEST version of each skill (not the pinned hash).
# Usage: install-skills.sh [--dry-run]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$REPO_DIR/library/skill-lock.json"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

[ -f "$LOCK" ] || { echo "no lockfile: $LOCK" >&2; exit 1; }

while IFS=$'\t' read -r src skills; do
  [ -n "$src" ] || continue
  echo "+ npx skills add $src -g -s $skills -y"
  if [ "$DRY" = 0 ]; then npx --yes skills add "$src" -g -s "$skills" -y; fi
done < <(python3 - "$LOCK" <<'PY'
import json, os, sys
lock = json.load(open(sys.argv[1]))
groups = {}
for name, e in lock.get("skills", {}).items():
    src = e.get("source")
    folder = os.path.basename(os.path.dirname(e.get("skillPath", ""))) or name
    if src:
        groups.setdefault(src, set()).add(folder)
for src, folders in sorted(groups.items()):
    print(f"{src}\t{','.join(sorted(folders))}")
PY
)

[ "$DRY" = 1 ] && echo "(dry-run: no skills installed)"
echo "done. source of truth: library/skill-lock.json"
