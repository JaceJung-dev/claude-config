#!/bin/bash
# Quality Check Hook (PostToolUse)
# Auto-detects project type and runs appropriate lint/type check on changed files.
# Only runs on the specific file that was edited.

set -euo pipefail

# Read hook input from stdin (JSON with tool info)
INPUT=$(cat)

# Extract file path from hook input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # PostToolUse provides tool_input with file_path
    path = data.get('tool_input', {}).get('file_path', '')
    if not path:
        path = data.get('tool_input', {}).get('path', '')
    print(path)
except:
    pass
" 2>/dev/null)

# Exit if no file path found
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Find project root by walking up directories
find_project_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || \
       [ -f "$dir/package.json" ] || [ -f "$dir/Cargo.toml" ] || \
       [ -f "$dir/CMakeLists.txt" ] || [ -f "$dir/.git" ] || [ -d "$dir/.git" ]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo ""
}

PROJECT_ROOT=$(find_project_root "$(dirname "$FILE_PATH")")
ERRORS=""

# Python files — use project .venv tools only
if [ "$EXT" = "py" ] && [ -n "$PROJECT_ROOT" ]; then
  VENV_BIN="$PROJECT_ROOT/.venv/bin"

  # ruff: fast linter (replaces flake8, isort, pyflakes)
  if [ -x "$VENV_BIN/ruff" ]; then
    RUFF_OUT=$("$VENV_BIN/ruff" check "$FILE_PATH" 2>&1) || true
    if [ -n "$RUFF_OUT" ]; then
      ERRORS="${ERRORS}[ruff] ${RUFF_OUT}\n"
    fi
  fi

  # mypy: type checker
  if [ -x "$VENV_BIN/mypy" ]; then
    MYPY_OUT=$("$VENV_BIN/mypy" "$FILE_PATH" --no-error-summary --no-color 2>&1) || true
    MYPY_OUT=$(echo "$MYPY_OUT" | grep -v "^Success" | grep -v "^$" || true)
    if [ -n "$MYPY_OUT" ]; then
      ERRORS="${ERRORS}[mypy] ${MYPY_OUT}\n"
    fi
  fi

# TypeScript / JavaScript files — use project node_modules tools only
elif ([ "$EXT" = "ts" ] || [ "$EXT" = "tsx" ] || [ "$EXT" = "js" ] || [ "$EXT" = "jsx" ]) && [ -n "$PROJECT_ROOT" ]; then
  NODE_BIN="$PROJECT_ROOT/node_modules/.bin"

  # eslint
  if [ -x "$NODE_BIN/eslint" ]; then
    ESLINT_OUT=$("$NODE_BIN/eslint" "$FILE_PATH" --no-color 2>&1) || true
    if [ -n "$ESLINT_OUT" ] && ! echo "$ESLINT_OUT" | grep -q "0 problems"; then
      ERRORS="${ERRORS}[eslint] ${ESLINT_OUT}\n"
    fi
  fi

  # tsc: type check (only for .ts/.tsx)
  if ([ "$EXT" = "ts" ] || [ "$EXT" = "tsx" ]) && [ -x "$NODE_BIN/tsc" ]; then
    TSC_OUT=$("$NODE_BIN/tsc" --noEmit --pretty false 2>&1) || true
    TSC_OUT=$(echo "$TSC_OUT" | grep "$FILE_PATH" || true)
    if [ -n "$TSC_OUT" ]; then
      ERRORS="${ERRORS}[tsc] ${TSC_OUT}\n"
    fi
  fi
fi

# Output errors if any
if [ -n "$ERRORS" ]; then
  echo "Quality issues found in $FILE_PATH:"
  echo -e "$ERRORS"
fi
