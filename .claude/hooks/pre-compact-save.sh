#!/bin/bash
# PreCompact: snapshot working state to tasks/handoff.md before context compaction.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
sid=$(hook_field '.session_id')
trigger=$(hook_field '.trigger')
cwd=$(hook_field '.cwd')
proj="${CLAUDE_PROJECT_DIR:-$cwd}"
[ -n "$proj" ] && [ -d "$proj" ] || exit 0

mkdir -p "$proj/tasks" 2>/dev/null || exit 0
{
  echo ""
  echo "### Compact snapshot $(date '+%Y-%m-%d %H:%M') (trigger: ${trigger:-unknown})"
  if git -C "$proj" rev-parse --git-dir >/dev/null 2>&1; then
    echo '```'
    git -C "$proj" status --short 2>/dev/null | head -20
    echo '```'
  fi
  ef="$HARNESS_TMP/$sid/edited.txt"
  if [ -s "$ef" ]; then
    echo "Edited this session:"
    sort -u "$ef" 2>/dev/null | sed 's/^/- /'
  fi
} >> "$proj/tasks/handoff.md" 2>/dev/null || exit 0

exit 0
