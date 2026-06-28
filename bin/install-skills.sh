#!/usr/bin/env bash
# Install/restore npx-managed third-party skills globally (bootstrap a fresh machine).
# These skills are NOT vendored in this repo — the Vercel `skills` CLI owns their bodies.
# Exact versions are recorded in library/skill-lock.json (mirror of ~/.agents/.skill-lock.json).
# Update later with:  npx skills update -g  &&  bin/sync-skills.sh
set -euo pipefail

npx --yes skills add vercel-labs/skills       -g -s find-skills -y
npx --yes skills add vercel-labs/agent-skills -g -s react-best-practices,web-design-guidelines -y
npx --yes skills add anthropics/skills        -g -s pptx -y

echo "done. recorded versions live in library/skill-lock.json"
