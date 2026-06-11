#!/bin/bash
# PostToolUse (Edit|Write|MultiEdit): record edited file paths for the Stop gate.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
sid=$(hook_field '.session_id')
dir=$(session_dir "$sid")
[ -n "$dir" ] || exit 0

printf '%s' "$HOOK_INPUT" \
  | jq -r '[.tool_input.file_path?] + [.tool_input.edits[]?.file_path?] | .[] | select(. != null and . != "")' 2>/dev/null \
  >> "$dir/edited.txt" || true

exit 0
