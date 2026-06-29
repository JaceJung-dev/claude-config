#!/usr/bin/env bash
# Capture installed plugins + their marketplaces into the repo manifest.
# Run after:  claude plugin install / uninstall / marketplace add ...
# Reads machine-local state (~/.claude/plugins/*.json), strips machine-specific
# fields (paths, versions, SHAs, timestamps), writes library/plugin-lock.json.
# Then review & commit the (small) diff.
# Captures USER-scope installs only (project/local installs are project-specific,
# not machine bootstrap material). The default marketplace is omitted (built-in).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
MARKETS="$HOME/.claude/plugins/known_marketplaces.json"
DEST="$REPO_DIR/library/plugin-lock.json"

[ -f "$INSTALLED" ] || { echo "no installed_plugins.json at $INSTALLED" >&2; exit 1; }
[ -f "$MARKETS" ]   || { echo "no known_marketplaces.json at $MARKETS" >&2; exit 1; }

python3 - "$INSTALLED" "$MARKETS" "$DEST" <<'PY'
import json, sys
installed = json.load(open(sys.argv[1]))
markets = json.load(open(sys.argv[2]))
dest = sys.argv[3]

DEFAULT_MARKETPLACE = "claude-plugins-official"  # built-in, no marketplace add needed

# user-scope installed plugins only (sorted for stable diffs)
plugins = sorted(
    name for name, records in installed.get("plugins", {}).items()
    if any(r.get("scope") == "user" for r in records)
)

# marketplaces referenced by those plugins, excluding the default
needed = {p.split("@", 1)[1] for p in plugins if "@" in p} - {DEFAULT_MARKETPLACE}

marketplaces = {}
for mk in sorted(needed):
    repo = markets.get(mk, {}).get("source", {}).get("repo")
    if repo:
        marketplaces[mk] = repo
    else:
        print(f"warning: no repo for marketplace '{mk}' in known_marketplaces.json", file=sys.stderr)

with open(dest, "w") as f:
    json.dump({"marketplaces": marketplaces, "plugins": plugins}, f, indent=2)
    f.write("\n")
PY

echo "synced: installed_plugins.json -> library/plugin-lock.json"
echo "review: git -C '$REPO_DIR' diff -- library/plugin-lock.json"
