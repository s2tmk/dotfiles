#!/bin/bash
# Synthetic-input regression tests for harness hooks. Run: bash run-tests.sh
set -u
H="$(cd "$(dirname "$0")" && pwd)"
SID="hooktest-$$"
TD="${TMPDIR:-/tmp}/hooktest-$$"
mkdir -p "$TD/proj/tasks"
pass=0; fail=0
ok()  { echo "PASS: $1"; pass=$((pass+1)); }
ng()  { echo "FAIL: $1"; fail=$((fail+1)); }

# 1) post-edit-accumulate
printf '{"session_id":"%s","tool_input":{"file_path":"/tmp/foo.ts"}}' "$SID" | bash "$H/post-edit-accumulate.sh"
grep -q "/tmp/foo.ts" "$HOME/.claude/tmp/harness/$SID/edited.txt" 2>/dev/null && ok "accumulate records edited file" || ng "accumulate"

# 2) post-bash-track
printf '{"session_id":"%s","tool_input":{"command":"npm test"}}' "$SID" | bash "$H/post-bash-track.sh"
grep -q "npm test" "$HOME/.claude/tmp/harness/$SID/commands.txt" 2>/dev/null && ok "bash-track records command" || ng "bash-track"

# 3) pre-config-guard blocks edits to existing configs
touch "$TD/eslint.config.mjs"
printf '{"tool_input":{"file_path":"%s"}}' "$TD/eslint.config.mjs" | bash "$H/pre-config-guard.sh" 2>/dev/null
[ $? -eq 2 ] && ok "config-guard blocks existing config (exit 2)" || ng "config-guard block"

# 4) pre-config-guard allows new config files
printf '{"tool_input":{"file_path":"%s/brand-new.eslintrc"}}' "$TD" | bash "$H/pre-config-guard.sh" && ok "config-guard allows new file" || ng "config-guard allow"

# 5) stop-verify: loop guard
printf '{"session_id":"%s","stop_hook_active":true}' "$SID" | bash "$H/stop-verify.sh" && ok "stop-verify loop guard exits 0" || ng "loop guard"

# 6) stop-verify: clears accumulator (file entries do not exist on disk -> exit 0)
printf '{"session_id":"%s","stop_hook_active":false}' "$SID" | bash "$H/stop-verify.sh" && ok "stop-verify exits 0 for stale entries" || ng "stale entries"
[ ! -f "$HOME/.claude/tmp/harness/$SID/edited.txt" ] && ok "clear-on-read removes accumulator" || ng "clear-on-read"

# 7) stop-verify blocks on a real TS type error (skipped unless scratch project provided)
if [ -n "${HOOKTEST_TS_PROJECT:-}" ] && [ -d "$HOOKTEST_TS_PROJECT" ]; then
  echo 'export const n: number = "oops";' > "$HOOKTEST_TS_PROJECT/src/broken.ts"
  mkdir -p "$HOME/.claude/tmp/harness/$SID"
  echo "$HOOKTEST_TS_PROJECT/src/broken.ts" > "$HOME/.claude/tmp/harness/$SID/edited.txt"
  printf '{"session_id":"%s","stop_hook_active":false}' "$SID" | bash "$H/stop-verify.sh" 2>"$TD/ts.err"
  [ $? -eq 2 ] && grep -q "broken.ts" "$TD/ts.err" && ok "stop-verify blocks on type error" || ng "type error block"
fi

# 8) session-start injects recent handoff
echo "next: finish X" > "$TD/proj/tasks/handoff.md"
CLAUDE_PROJECT_DIR="$TD/proj" bash "$H/session-start.sh" <<< "{\"cwd\":\"$TD/proj\"}" | grep -q "finish X" && ok "session-start injects handoff" || ng "session-start"

# 9) pre-compact-save appends snapshot
printf '{"session_id":"%s","trigger":"manual","cwd":"%s"}' "$SID" "$TD/proj" | CLAUDE_PROJECT_DIR="$TD/proj" bash "$H/pre-compact-save.sh"
grep -q "Compact snapshot" "$TD/proj/tasks/handoff.md" && ok "pre-compact-save writes snapshot" || ng "pre-compact-save"

# 10) kill switch disables blocking
printf '{"tool_input":{"file_path":"%s/eslint.config.mjs"}}' "$TD" | HARNESS_HOOKS=off bash "$H/pre-config-guard.sh" && ok "HARNESS_HOOKS=off bypasses guard" || ng "kill switch"

# 11) new config file with weakened strictness -> blocked
printf '{"tool_input":{"file_path":"%s/tsconfig.loose.json","content":"{\\"compilerOptions\\":{\\"strict\\": false}}"}}' "$TD" | bash "$H/pre-config-guard.sh" 2>/dev/null
[ $? -eq 2 ] && ok "config-guard blocks new weakening config" || ng "new weakening config"

# 12) new config file with strict settings -> allowed
printf '{"tool_input":{"file_path":"%s/tsconfig.strict.json","content":"{\\"compilerOptions\\":{\\"strict\\": true}}"}}' "$TD" | bash "$H/pre-config-guard.sh" && ok "config-guard allows strict new config" || ng "strict new config"

# 13) stop-verify blocks once when tsc is missing for edited TS files
mkdir -p "$TD/tsless/src"
echo '{}' > "$TD/tsless/tsconfig.json"
echo 'export const x = 1;' > "$TD/tsless/src/a.ts"
mkdir -p "$HOME/.claude/tmp/harness/$SID"
echo "$TD/tsless/src/a.ts" > "$HOME/.claude/tmp/harness/$SID/edited.txt"
printf '{"session_id":"%s","stop_hook_active":false}' "$SID" | bash "$H/stop-verify.sh" 2>"$TD/tscmiss.err"
[ $? -eq 2 ] && grep -q "tsc not found" "$TD/tscmiss.err" && ok "stop-verify surfaces missing tsc (exit 2)" || ng "missing tsc surfacing"
printf '{"session_id":"%s","stop_hook_active":false}' "$SID" | bash "$H/stop-verify.sh" && ok "second stop passes (warn-once)" || ng "warn-once after tsc-missing"

# cleanup (no rm -rf; targeted files only)
rm -r "$HOME/.claude/tmp/harness/$SID" 2>/dev/null
rm -r "$TD" 2>/dev/null
echo "----------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
