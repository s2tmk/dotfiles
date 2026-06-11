#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): block edits that weaken lint/format/type configs.
# Creating a NEW config file is allowed; editing an existing one is blocked with guidance.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
fp=$(hook_field '.tool_input.file_path')
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0  # new files are fine

base=$(basename "$fp")
case "$base" in
  .eslintrc|.eslintrc.*|eslint.config.*|\
  .prettierrc|.prettierrc.*|prettier.config.*|\
  biome.json|biome.jsonc|\
  tsconfig.json|tsconfig.*.json|\
  .ruff.toml|ruff.toml|.flake8|mypy.ini|\
  .golangci.yml|.golangci.yaml|rustfmt.toml|.rustfmt.toml)
    echo "Blocked: do not edit lint/format/type configs to make failing checks pass — fix the code instead. If this config change is genuinely required (new path alias, new include, etc.), explain why and ask the user to approve it; they can run with HARNESS_HOOKS=off for one session." >&2
    exit 2
    ;;
esac

exit 0
