#!/bin/bash
# Stop gate: batch format + typecheck of files edited this session.
# TS always; Python/Go/Rust only when the project demonstrably uses the tool.
# Modes via HARNESS_STOP_GATE: block (default) | strict (tests required too) | off
# Wired to Stop AND TeammateIdle (agent teams): teammate Stop firing is not
# documented, so TeammateIdle guarantees coverage; clear-on-read makes a
# double firing idempotent (second run sees an empty accumulator, exits 0).
# Loop safety: exits 0 when stop_hook_active; accumulator is clear-on-read,
# so a block fires at most once per batch of edits.
set -u
source "$(dirname "$0")/lib.sh" || exit 0

GATE_MODE="${HARNESS_STOP_GATE:-block}"
[ "$GATE_MODE" = "off" ] && exit 0

read_hook_input
[ "$(hook_field '.stop_hook_active')" = "true" ] && exit 0

sid=$(hook_field '.session_id')
dir=$(session_dir "$sid")
[ -n "$dir" ] || exit 0
list="$dir/edited.txt"
[ -s "$list" ] || exit 0

# clear-on-read: keep only files that still exist, then drop the accumulator
edited=$(sort -u "$list" | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done)
rm -f "$list" 2>/dev/null
[ -n "$edited" ] || exit 0

# --- 1) Format (never blocks; tool missing => silent skip) -------------------
# Package-runner detection: pnpm/yarn repos don't always expose bins via npx.
# Walks up so monorepo packages find the workspace-root lockfile.
runner_for() {
  local d="$1"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    if [ -f "$d/pnpm-lock.yaml" ]; then echo "pnpm exec"; return; fi
    if [ -f "$d/yarn.lock" ]; then echo "yarn"; return; fi
    if [ -f "$d/bun.lockb" ] || [ -f "$d/bun.lock" ]; then echo "bunx"; return; fi
    if [ -f "$d/package-lock.json" ]; then break; fi
    d=$(dirname "$d")
  done
  echo "npx --no-install"
}

ts_js=$(printf '%s\n' "$edited" | grep -E '\.(ts|tsx|mts|cts|js|jsx|mjs|cjs)$' || true)
if [ -n "$ts_js" ]; then
  while IFS= read -r f; do
    pkgdir=$(nearest_up "$f" package.json) || continue
    run=$(runner_for "$pkgdir")
    if [ -f "$pkgdir/biome.json" ] || [ -f "$pkgdir/biome.jsonc" ]; then
      (cd "$pkgdir" && timeout 60 $run biome check --write "$f" >/dev/null 2>&1) || true
    elif compgen -G "$pkgdir/.prettierrc*" >/dev/null 2>&1 \
      || compgen -G "$pkgdir/prettier.config.*" >/dev/null 2>&1; then
      (cd "$pkgdir" && timeout 60 $run prettier --write "$f" >/dev/null 2>&1) || true
    fi
  done <<< "$ts_js"
fi

# --- 2) Typecheck (blocking; missing tsc surfaces once instead of silently passing)
errors=""
tsc_missing=""
ts_only=$(printf '%s\n' "$edited" | grep -E '\.(ts|tsx|mts|cts)$' || true)
if [ -n "$ts_only" ]; then
  tsdirs=$(while IFS= read -r f; do nearest_up "$f" tsconfig.json || true; done <<< "$ts_only" | sort -u)
  while IFS= read -r tdir; do
    [ -n "$tdir" ] || continue
    trun=$(runner_for "$tdir")
    if ! (cd "$tdir" && $trun tsc --version >/dev/null 2>&1); then
      tsc_missing="$tsc_missing $tdir"
      continue
    fi
    out=$( (cd "$tdir" && timeout 240 $trun tsc --noEmit --pretty false 2>&1) || true )
    [ -n "$out" ] || continue
    # only surface errors that mention files edited this session
    # (basename fallback: tsc may emit rootDir-relative paths)
    rel=$(printf '%s\n' "$ts_only" | while IFS= read -r f; do
      [[ "$f" == "$tdir"/* ]] || continue
      printf '%s\n' "${f#"$tdir"/}"
      basename "$f"
    done | sort -u)
    [ -n "$rel" ] || continue
    hits=$(printf '%s\n' "$out" | grep -F -f <(printf '%s\n' "$rel") 2>/dev/null | head -40 || true)
    [ -n "$hits" ] && errors="${errors}
[tsconfig: $tdir]
$hits"
  done <<< "$tsdirs"
fi

# --- 2b) Python typecheck (only when the project demonstrably configures
# mypy or pyright; missing tool/config => silent skip — never a false block)
py_only=$(printf '%s\n' "$edited" | grep -E '\.py$' || true)
if [ -n "$py_only" ]; then
  py_map=$(while IFS= read -r f; do
    tool=""; root=""
    if root=$(nearest_up "$f" mypy.ini); then tool="mypy"
    elif root=$(nearest_up "$f" setup.cfg) && grep -q '^\[mypy\]' "$root/setup.cfg" 2>/dev/null; then tool="mypy"
    elif root=$(nearest_up "$f" pyproject.toml) && grep -qE '^\[tool\.mypy(\]|\.)' "$root/pyproject.toml" 2>/dev/null; then tool="mypy"
    elif root=$(nearest_up "$f" pyrightconfig.json); then tool="pyright"
    else continue
    fi
    printf '%s\t%s\t%s\n' "$tool" "$root" "$f"
  done <<< "$py_only" | sort -u)
  py_groups=$(printf '%s\n' "$py_map" | cut -f1,2 | sort -u)
  while IFS=$'\t' read -r ptool proot; do
    [ -n "$proot" ] || continue
    command -v "$ptool" >/dev/null 2>&1 || continue
    rels=$(printf '%s\n' "$py_map" | while IFS=$'\t' read -r t r f; do
      [ "$t" = "$ptool" ] && [ "$r" = "$proot" ] && printf '%s\n' "${f#"$proot"/}" || true
    done)
    [ -n "$rels" ] || continue
    pargs=()
    while IFS= read -r rf; do pargs+=("$rf"); done <<< "$rels"
    if [ "$ptool" = "mypy" ]; then
      out=$( (cd "$proot" && timeout 120 mypy --no-error-summary "${pargs[@]}" 2>/dev/null) || true )
    else
      out=$( (cd "$proot" && timeout 120 pyright "${pargs[@]}" 2>/dev/null) || true )
    fi
    [ -n "$out" ] || continue
    pats=$( { printf '%s\n' "$rels"; while IFS= read -r rf; do basename "$rf"; done <<< "$rels"; } | sort -u)
    hits=$(printf '%s\n' "$out" | grep -F ' error:' | grep -F -f <(printf '%s\n' "$pats") 2>/dev/null | head -40 || true)
    [ -n "$hits" ] && errors="${errors}
[$ptool: $proot]
$hits"
  done <<< "$py_groups"
fi

# --- 2c) Go vet on packages containing edited files (go.mod projects only)
go_only=$(printf '%s\n' "$edited" | grep -E '\.go$' || true)
if [ -n "$go_only" ] && command -v go >/dev/null 2>&1; then
  godirs=$(printf '%s\n' "$go_only" | while IFS= read -r f; do
    nearest_up "$f" go.mod >/dev/null && dirname "$f" || true
  done | sort -u)
  while IFS= read -r gdir; do
    [ -n "$gdir" ] || continue
    gnames=$(printf '%s\n' "$go_only" | while IFS= read -r f; do
      [ "$(dirname "$f")" = "$gdir" ] && basename "$f" || true
    done | sort -u)
    [ -n "$gnames" ] || continue
    out=$( (cd "$gdir" && timeout 120 go vet . 2>&1) || true )
    [ -n "$out" ] || continue
    # only surface lines mentioning edited files (env failures never block)
    hits=$(printf '%s\n' "$out" | grep -F -f <(printf '%s\n' "$gnames") 2>/dev/null | head -40 || true)
    [ -n "$hits" ] && errors="${errors}
[go vet: $gdir]
$hits"
  done <<< "$godirs"
fi

# --- 2d) Rust cargo check (Cargo.toml projects only)
rs_only=$(printf '%s\n' "$edited" | grep -E '\.rs$' || true)
if [ -n "$rs_only" ] && command -v cargo >/dev/null 2>&1; then
  crates=$(printf '%s\n' "$rs_only" | while IFS= read -r f; do
    nearest_up "$f" Cargo.toml || true
  done | sort -u)
  while IFS= read -r cdir; do
    [ -n "$cdir" ] || continue
    rnames=$(printf '%s\n' "$rs_only" | while IFS= read -r f; do
      [[ "$f" == "$cdir"/* ]] || continue
      printf '%s\n' "${f#"$cdir"/}"
      basename "$f"
    done | sort -u)
    [ -n "$rnames" ] || continue
    out=$( (cd "$cdir" && timeout 240 cargo check --quiet --message-format=short 2>&1) || true )
    [ -n "$out" ] || continue
    hits=$(printf '%s\n' "$out" | grep -E 'error(\[[A-Za-z0-9]+\])?:' | grep -F -f <(printf '%s\n' "$rnames") 2>/dev/null | head -40 || true)
    [ -n "$hits" ] && errors="${errors}
[cargo check: $cdir]
$hits"
  done <<< "$crates"
fi

# --- 3) Test reminder (warn-once in block mode; strict mode also blocks) ------
# Threshold: >=3 source files, OR >=1 file in a security-sensitive path.
reminder=""
nfiles=$(printf '%s\n' "$edited" | grep -cE '\.(ts|tsx|js|jsx|py|go|rs|rb|swift|kt)$' 2>/dev/null || true)
sensitive=$(printf '%s\n' "$edited" | grep -icE '(auth|login|session|payment|billing|secret|token|middleware|permission)' 2>/dev/null || true)
tests_ran=true
grep -qE '(vitest|jest|playwright|pytest|go test|cargo test|(npm|pnpm|yarn|bun)( run)? test|(make|just|task)[[:space:]]+[a-z-]*test)' "$dir/commands.txt" 2>/dev/null || tests_ran=false
if [ "$tests_ran" = "false" ]; then
  if [ "${sensitive:-0}" -ge 1 ]; then
    reminder="Note: security-sensitive files (auth/payment/session/...) were edited but no test runner ran this session. Run the relevant tests before declaring this done."
  elif [ "${nfiles:-0}" -ge 3 ]; then
    reminder="Note: ${nfiles} source files were edited but no test runner ran this session. Run the relevant tests before declaring this done."
  fi
fi

if [ -n "$errors" ] || [ -n "$tsc_missing" ]; then
  {
    if [ -n "$errors" ]; then
      echo "Stop gate: typecheck errors in files you edited this session. Fix them before finishing:"
      echo "$errors"
    fi
    if [ -n "$tsc_missing" ]; then
      echo "Stop gate: tsc not found in:$tsc_missing — typecheck could NOT run on edited TS files. Run the project's own check script (e.g. npm run typecheck / build) to verify types, then finish. (This warning fires once per edit batch.)"
    fi
    [ -n "$reminder" ] && echo "$reminder"
  } >&2
  exit 2
fi

if [ -n "$reminder" ]; then
  if [ "$GATE_MODE" = "strict" ]; then
    echo "Stop gate (strict): $reminder" >&2
  else
    # Stop hooks only reach the model via exit 2 + stderr (exit 0 output goes
    # to the transcript, not the model). Mirror the tsc-missing warn-once
    # mechanism: the accumulator is clear-on-read, so the next stop passes.
    echo "Stop gate: $reminder (This reminder fires once per edit batch.)" >&2
  fi
  exit 2
fi

exit 0
