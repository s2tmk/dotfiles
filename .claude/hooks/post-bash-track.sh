#!/bin/bash
# PostToolUse (Bash): record executed commands so the Stop gate can tell
# whether tests were actually run this session.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
sid=$(hook_field '.session_id')
dir=$(session_dir "$sid")
[ -n "$dir" ] || exit 0

cmd=$(hook_field '.tool_input.command')
[ -n "$cmd" ] && printf '%s\n' "$cmd" >> "$dir/commands.txt" 2>/dev/null

exit 0
