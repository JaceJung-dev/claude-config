#!/usr/bin/env bash
# Capture the global skills lockfile into the repo after updating skills.
# Run after:  npx skills update -g
# Then review & commit the (small) diff in library/skill-lock.json.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$HOME/.agents/.skill-lock.json"
DEST="$REPO_DIR/library/skill-lock.json"

if [ ! -f "$SRC" ]; then echo "no lockfile at $SRC" >&2; exit 1; fi
cp "$SRC" "$DEST"
echo "synced: $SRC -> library/skill-lock.json"
echo "review: git -C '$REPO_DIR' diff -- library/skill-lock.json"
