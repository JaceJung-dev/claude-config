#!/usr/bin/env bash
# Install all skills for this machine, globally:
#   - vendored skills    (library/skills/*)       -> symlinked into ~/.claude/skills/
#   - third-party skills (npx skills, lockfile)   -> installed to ~/.agents/skills/
#                                                    (npx -g also links them into ~/.claude/skills/)
# Single source of truth for third-party: library/skill-lock.json — add/remove via
# `npx skills add/remove -g` + bin/sync-skills.sh, and this script follows automatically.
# Note: installs the LATEST version of each third-party skill (not the pinned hash).
# Usage: install-skills.sh [--dry-run]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$REPO_DIR/library/skill-lock.json"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

# --- vendored skills: link library/skills/* into ~/.claude/skills/ (global) ---
# Skills only load their name+description until invoked, so making them global is
# cheap — same place npx puts the third-party ones. Real (non-symlink) collisions
# are backed up to *.bak first.
SKILLS_SRC="$REPO_DIR/library/skills"
SKILLS_DEST="$HOME/.claude/skills"
if [ -d "$SKILLS_SRC" ]; then
  if [ "$DRY" = 0 ]; then mkdir -p "$SKILLS_DEST"; fi
  for d in "$SKILLS_SRC"/*/; do
    [ -d "$d" ] || continue
    dest="$SKILLS_DEST/$(basename "$d")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      echo "backup: $dest -> $dest.bak"
      if [ "$DRY" = 0 ]; then mv "$dest" "$dest.bak"; fi
    fi
    echo "+ link $dest -> ${d%/}"
    if [ "$DRY" = 0 ]; then ln -sfn "${d%/}" "$dest"; fi
  done
fi

# --- third-party skills: install globally from the lockfile via npx ---
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

[ "$DRY" = 1 ] && echo "(dry-run: nothing installed)"
echo "done. vendored: library/skills/  |  third-party source of truth: library/skill-lock.json"
