#!/usr/bin/env bash
# Bootstrap a project's .claude/ with chosen skills (symlinked) and plugins.
# Usage: init-project.sh [--skills a,b] [--plugin x,y] [--path DIR]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO_DIR/library/skills"
TEMPLATE="$REPO_DIR/templates/project/.claude/settings.json"

SKILLS=""; PLUGINS=""; TARGET="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --skills) SKILLS="$2"; shift 2;;
    --plugin) PLUGINS="$2"; shift 2;;
    --path)   TARGET="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done

CLAUDE_DIR="$TARGET/.claude"
mkdir -p "$CLAUDE_DIR"
[ -f "$CLAUDE_DIR/settings.json" ] || cp "$TEMPLATE" "$CLAUDE_DIR/settings.json"

if [ -n "$PLUGINS" ]; then
  IFS=',' read -ra PARR <<< "$PLUGINS"
  for p in "${PARR[@]}"; do
    python3 - "$CLAUDE_DIR/settings.json" "$p" <<'PY'
import json, sys
f, plugin = sys.argv[1], sys.argv[2]
d = json.load(open(f))
ep = d.setdefault("enabledPlugins", {})
mapping = {
    "superpowers": "superpowers@claude-plugins-official",
    "skill-creator": "skill-creator@claude-plugins-official",
    "plannotator": "plannotator@plannotator",
}
ep[mapping.get(plugin, plugin)] = True
json.dump(d, open(f, "w"), indent=2)
PY
  done
fi

if [ -n "$SKILLS" ]; then
  mkdir -p "$CLAUDE_DIR/skills"
  IFS=',' read -ra SARR <<< "$SKILLS"
  for s in "${SARR[@]}"; do
    if [ -d "$LIB/$s" ]; then
      ln -sfn "$LIB/$s" "$CLAUDE_DIR/skills/$s"; echo "skill linked: $s"
    else
      echo "skill not found in library: $s" >&2
    fi
  done
fi
echo "init done: $CLAUDE_DIR"
