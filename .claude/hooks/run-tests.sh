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

# 14) prompt-router: incidental English words must not route to UI
out=$(printf '{"prompt":"system design review"}' | bash "$H/prompt-router.sh")
printf '%s\n' "$out" | grep -q "ux-ui-design" && ng "router routes 'system design review' to UI" || ok "router ignores 'system design review'"

# 15) prompt-router: UI-intent prompts still route (JA + EN)
out=$(printf '{"prompt":"ダッシュボード画面のデザイン"}' | bash "$H/prompt-router.sh")
printf '%s\n' "$out" | grep -q "ux-ui-design" && ok "router routes JA dashboard/screen prompt to UI" || ng "router misses JA UI prompt"
out=$(printf '{"prompt":"landing page design"}' | bash "$H/prompt-router.sh")
printf '%s\n' "$out" | grep -q "ux-ui-design" && ok "router routes 'landing page design' to UI" || ng "router misses 'landing page design'"

# 16) prompt-router: bare 'spec' no longer triggers the requirements route
out=$(printf '{"prompt":"performance spec"}' | bash "$H/prompt-router.sh")
[ -z "$out" ] && ok "router ignores 'performance spec'" || ng "router emitted for 'performance spec'"

# 17) prompt-router: 4+ matched domains are not truncated
out=$(printf '{"prompt":"新機能のUI画面、市場調査、事業計画、ピッチ資料、AWSインフラ"}' | bash "$H/prompt-router.sh")
n=$(printf '%s\n' "$out" | grep -c "^Routing:")
[ "$n" -ge 4 ] && ok "router emits all matched domains (n=$n)" || ng "router truncated output (n=$n)"

# 18) stop-verify: test reminder reaches the model in block mode (no TS errors)
SIDR="${SID}-rem"
mkdir -p "$TD/pyproj"
printf 'x = 1\n' > "$TD/pyproj/a.py"
printf 'x = 1\n' > "$TD/pyproj/b.py"
printf 'x = 1\n' > "$TD/pyproj/c.py"
mkdir -p "$HOME/.claude/tmp/harness/$SIDR"
printf '%s\n%s\n%s\n' "$TD/pyproj/a.py" "$TD/pyproj/b.py" "$TD/pyproj/c.py" > "$HOME/.claude/tmp/harness/$SIDR/edited.txt"
printf '{"session_id":"%s","stop_hook_active":false}' "$SIDR" | HARNESS_STOP_GATE=block bash "$H/stop-verify.sh" 2>"$TD/rem.err"
[ $? -eq 2 ] && grep -q "no test runner ran" "$TD/rem.err" && ok "stop-verify surfaces test reminder in block mode (exit 2)" || ng "block-mode reminder"
printf '{"session_id":"%s","stop_hook_active":false}' "$SIDR" | HARNESS_STOP_GATE=block bash "$H/stop-verify.sh" && ok "second stop passes after reminder (warn-once)" || ng "warn-once after reminder"

# 19) lib.sh: nearest_up with empty input fails fast instead of looping
# (perl alarm = portable watchdog; coreutils timeout is not always in PATH)
HARNESS_HOOKS=on perl -e 'alarm 5; exec @ARGV' bash -c "source '$H/lib.sh'; nearest_up '' anyfile"
[ $? -eq 1 ] && ok "nearest_up empty-input guard returns 1 promptly" || ng "nearest_up empty-input guard"

# 20) stop-verify: python gate skips cleanly when no mypy/pyright config exists
SIDP="${SID}-pys"
printf 'y = 2\n' > "$TD/pyproj/solo.py"
mkdir -p "$HOME/.claude/tmp/harness/$SIDP"
printf '%s\n' "$TD/pyproj/solo.py" > "$HOME/.claude/tmp/harness/$SIDP/edited.txt"
printf '{"session_id":"%s","stop_hook_active":false}' "$SIDP" | HARNESS_STOP_GATE=block bash "$H/stop-verify.sh" 2>"$TD/pys.err"
[ $? -eq 0 ] && [ ! -s "$TD/pys.err" ] && ok "python gate skips cleanly without mypy config" || ng "python gate skip"

# cleanup (no rm -rf; targeted files only)
rm -r "$HOME/.claude/tmp/harness/$SID" "$HOME/.claude/tmp/harness/$SIDR" "$HOME/.claude/tmp/harness/$SIDP" 2>/dev/null
rm -r "$TD" 2>/dev/null
echo "----------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
