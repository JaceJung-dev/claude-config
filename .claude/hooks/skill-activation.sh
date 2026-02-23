#!/bin/bash
# Skill Auto-Activation Hook
# Triggered on UserPromptSubmit — reads user prompt from stdin,
# matches against skill-rules.json keywords, and suggests relevant skills.

set -euo pipefail

RULES_FILE="$HOME/.claude/hooks/skill-rules.json"

# Exit silently if rules file doesn't exist
if [ ! -f "$RULES_FILE" ]; then
  exit 0
fi

# Read user prompt from stdin (Claude hooks pass prompt via stdin)
USER_PROMPT=$(cat)

# Use Python for reliable JSON parsing + keyword matching
MATCHED=$(PROMPT_INPUT="$USER_PROMPT" python3 << 'PYEOF'
import json, os, sys

rules_file = os.path.expanduser("~/.claude/hooks/skill-rules.json")
prompt = os.environ.get("PROMPT_INPUT", "").lower()

if not prompt:
    sys.exit(0)

try:
    with open(rules_file) as f:
        rules = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(0)

matched = []
for skill in rules.get("skills", []):
    name = skill.get("name", "")
    keywords = skill.get("keywords", [])

    for kw in keywords:
        if kw.lower() in prompt:
            matched.append(name)
            break

if matched:
    print(", ".join(matched))
PYEOF
)

# If skills matched, output suggestion to Claude
if [ -n "$MATCHED" ]; then
  echo "Relevant skills detected: $MATCHED"
  echo "Read the corresponding SKILL.md files in ~/.claude/skills/ for guidelines before implementing."
fi
