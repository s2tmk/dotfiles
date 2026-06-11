#!/bin/bash
# SessionStart: inject the previous session handoff, if recent. Hard cap 2KB.
# (Native memory already injects MEMORY.md — this only covers tasks/handoff.md.)
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
cwd=$(hook_field '.cwd')
proj="${CLAUDE_PROJECT_DIR:-$cwd}"
f="$proj/tasks/handoff.md"
[ -f "$f" ] || exit 0
# only if modified within the last 7 days
[ -n "$(find "$f" -mtime -7 2>/dev/null)" ] || exit 0

echo "## Previous session handoff (tasks/handoff.md — delete the file once resolved)"
tail -n 60 "$f" 2>/dev/null | head -c 2048
echo ""
exit 0
