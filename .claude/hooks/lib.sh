#!/bin/bash
# Shared helpers for harness hooks.
# Kill switch: HARNESS_HOOKS=off disables every hook instantly.
# Design rule: hooks must NEVER block by accident — any internal error exits 0.

[ "${HARNESS_HOOKS:-on}" = "off" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

HARNESS_TMP="$HOME/.claude/tmp/harness"

# Reads up to 1MB of stdin into $HOOK_INPUT.
read_hook_input() {
  HOOK_INPUT=$(head -c 1048576) || HOOK_INPUT=""
}

# jq over $HOOK_INPUT; empty string on failure.
hook_field() {
  printf '%s' "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null || true
}

# Per-session scratch dir; echoes path (empty on failure).
session_dir() {
  local sid="$1"
  [ -n "$sid" ] || return 0
  local d="$HARNESS_TMP/$sid"
  mkdir -p "$d" 2>/dev/null || return 0
  echo "$d"
}

# Walk up from a file to the nearest directory containing $2; echoes dir or fails.
nearest_up() {
  local d
  d=$(dirname "$1")
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ -e "$d/$2" ] && { echo "$d"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}
