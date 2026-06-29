#!/usr/bin/env bash
# Install Claude Code plugins on this machine from the manifest (latest versions).
# `claude plugin install` auto-enables at the install scope, which would mutate
# ~/.claude/settings.json (the repo symlink). To keep ENABLE state owned solely by
# settings.json, we snapshot it before installing and restore it after (even on
# failure). Plugin bodies land in the global cache regardless; only enable is reset.
#   install set : library/plugin-lock.json     (this file decides WHAT to install)
#   enable state: global/settings.json         (enabledPlugins decides WHAT is on)
# Note: `claude plugin install` has no --yes; a new marketplace may prompt to trust
# on first add (interactive only — fails in headless/CI).
# Usage: install-plugins.sh [--dry-run]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$REPO_DIR/library/plugin-lock.json"
SETTINGS="$HOME/.claude/settings.json"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

[ -f "$LOCK" ] || { echo "no manifest: $LOCK" >&2; exit 1; }

# --- snapshot settings.json so plugin install can't change enable state ---
BACKUP=""
restore_settings() {
  if [ -n "${BACKUP:-}" ] && [ -f "$BACKUP" ]; then
    cp "$BACKUP" "$SETTINGS"
    rm -f "$BACKUP"
    echo "restored settings.json (enable state preserved)"
  fi
}
if [ "$DRY" = 0 ] && [ -f "$SETTINGS" ]; then
  BACKUP="$(mktemp)"
  cp "$SETTINGS" "$BACKUP"
  trap restore_settings EXIT   # safety net: restore even if install aborts
fi

# --- 1. register non-default marketplaces (claude-plugins-official is built-in) ---
while IFS=$'\t' read -r name repo; do
  [ -n "$repo" ] || continue
  echo "+ claude plugin marketplace add $repo"
  if [ "$DRY" = 0 ]; then claude plugin marketplace add "$repo" || echo "  (marketplace add failed: $repo)"; fi
done < <(python3 - "$LOCK" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
for name, repo in sorted(lock.get("marketplaces", {}).items()):
    print(f"{name}\t{repo}")
PY
)

# --- 2. install plugins at user scope (auto-enables; settings restored below) ---
while IFS= read -r plugin; do
  [ -n "$plugin" ] || continue
  echo "+ claude plugin install $plugin --scope user"
  if [ "$DRY" = 0 ]; then claude plugin install "$plugin" --scope user || echo "  (install failed: $plugin)"; fi
done < <(python3 - "$LOCK" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
for p in lock.get("plugins", []):
    print(p)
PY
)

# --- restore BEFORE reporting so we read the true committed enable state ---
[ "$DRY" = 0 ] && restore_settings
[ "$DRY" = 1 ] && echo "(dry-run: nothing installed, settings.json untouched)"

# --- 3. report enable state from the committed settings.json (install never sets it) ---
echo
echo "enable state (from global/settings.json — install does not change this):"
python3 - "$REPO_DIR/global/settings.json" "$LOCK" <<'PY'
import json, sys
settings = json.load(open(sys.argv[1]))
lock = json.load(open(sys.argv[2]))
enabled = settings.get("enabledPlugins", {})
for p in lock.get("plugins", []):
    state = "enabled (global)" if enabled.get(p) else "installed only (not globally enabled)"
    print(f"  {p}: {state}")
PY

echo "done. install set: library/plugin-lock.json | enable: global/settings.json"
