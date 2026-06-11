#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): block edits that weaken lint/format/type configs.
# Creating a NEW config file is allowed; editing an existing one is blocked with guidance.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

read_hook_input
fp=$(hook_field '.tool_input.file_path')
[ -n "$fp" ] || exit 0

base=$(basename "$fp")

# New config files are allowed UNLESS their content weakens strictness
# (blocks the "create tsconfig.loose.json instead of editing" loophole).
if [ ! -f "$fp" ]; then
  case "$base" in
    tsconfig*.json|.eslintrc*|eslint.config.*|biome.json|biome.jsonc)
      content=$(hook_field '.tool_input.content')
      if printf '%s' "$content" | grep -qE '"(strict|strictNullChecks|noImplicitAny|noUnusedLocals|alwaysStrict)"[[:space:]]*:[[:space:]]*false|"skipLibCheck"[[:space:]]*:[[:space:]]*true'; then
        echo "Blocked: this new config file weakens type/lint strictness (strict:false etc.). Fix the failing code instead of creating a looser config. If genuinely required, explain why and get the user's approval." >&2
        exit 2
      fi
      ;;
  esac
  exit 0
fi
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
