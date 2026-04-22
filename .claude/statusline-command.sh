#!/usr/bin/env bash
# Claude Code Status Line
# stdin から JSON を受け取り、フォーマットされたステータスラインを出力する

set -uo pipefail

if ! command -v jq &>/dev/null; then
  printf '⚠️  jq required'
  exit 0
fi

DATA=$(cat)

# ANSI
R=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

# JSON パース（単一 jq 呼び出し）
IFS=$'\x1f' read -r CWD MODEL CTX_PCT FIVE_PCT FIVE_RESET SEVEN_PCT SEVEN_RESET < <(
  printf '%s' "$DATA" | jq -j '[
    (.cwd // ""),
    (.model.display_name // "Claude"),
    (if .context_window.used_percentage != null then (.context_window.used_percentage | tostring) else "" end),
    (if .rate_limits.five_hour.used_percentage != null then (.rate_limits.five_hour.used_percentage | tostring) else "" end),
    (if .rate_limits.five_hour.resets_at != null then (.rate_limits.five_hour.resets_at | tostring) else "" end),
    (if .rate_limits.seven_day.used_percentage != null then (.rate_limits.seven_day.used_percentage | tostring) else "" end),
    (if .rate_limits.seven_day.resets_at != null then (.rate_limits.seven_day.resets_at | tostring) else "" end)
  ] | join("")' 2>/dev/null
) || true

CWD="${CWD:-$PWD}"
MODEL="${MODEL:-Claude}"
DIR="${CWD/#$HOME/~}"

BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
GIT_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)
PROJECT="${GIT_ROOT:+$(basename "$GIT_ROOT")}"
PROJECT="${PROJECT:-$(basename "$CWD")}"

# パーセントに応じた RGB カラー（緑→黄→赤グラデーション）
pct_color() {
  local pct=${1:-0}
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  if (( pct < 50 )); then
    printf '\033[38;2;%d;200;80m' "$(( pct * 5 ))"
  else
    local g=$(( 200 - (pct - 50) * 4 ))
    (( g < 0 )) && g=0
    printf '\033[38;2;255;%d;60m' "$g"
  fi
}

# プログレスバー
progress_bar() {
  local pct=${1:-0}
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  local width=20
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))

  printf '%s' "$(pct_color "$pct")"
  for (( i = 0; i < filled; i++ )); do printf '█'; done
  printf '%s' "$DIM"
  for (( i = 0; i < empty; i++ )); do printf '░'; done
  printf '%s' "$R"
}

# Unix epoch をリセット時刻文字列に変換（macOS date -r）
format_reset() {
  local epoch=${1%.*}
  [[ -z "$epoch" || "$epoch" == "null" ]] && return

  local today reset_day
  today=$(date +%Y-%m-%d)
  reset_day=$(date -r "$epoch" +%Y-%m-%d 2>/dev/null) || return

  if [[ "$reset_day" == "$today" ]]; then
    LC_TIME=C date -r "$epoch" +"%-I%p" 2>/dev/null | tr '[:upper:]' '[:lower:]'
  else
    printf '%s %s' \
      "$(LC_TIME=C date -r "$epoch" +"%-m/%-d" 2>/dev/null)" \
      "$(LC_TIME=C date -r "$epoch" +"%-I%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  fi
}

# ─── 出力 ───

# Line 1: 📁 ディレクトリ
printf '📁 %s%s%s\n' "$DIM" "$DIR" "$R"

# Line 2: 🌲 プロジェクト | 🌿 ブランチ
if [[ -n "$BRANCH" ]]; then
  printf '🌲 %s%s%s %s|%s 🌿 %s%s%s\n' \
    "$BOLD" "$PROJECT" "$R" "$DIM" "$R" "$BOLD" "$BRANCH" "$R"
fi

# Line 3: 📝 コンテキスト使用率 | 🧠 モデル
if [[ -n "$CTX_PCT" ]]; then
  ctx_int=${CTX_PCT%.*}
  printf '📝 '
  progress_bar "$ctx_int"
  printf ' %s%s%%%s %s|%s 🧠 %s%s%s\n' \
    "$BOLD" "$ctx_int" "$R" "$DIM" "$R" "$BOLD" "$MODEL" "$R"
else
  printf '🧠 %s%s%s\n' "$BOLD" "$MODEL" "$R"
fi

# Line 4: 🕰️ レート制限
if [[ -n "$FIVE_PCT" || -n "$SEVEN_PCT" ]]; then
  printf '🕰️ '

  if [[ -n "$FIVE_PCT" ]]; then
    five_int=${FIVE_PCT%.*}
    printf '5h %s%s%%%s' "$(pct_color "$five_int")$BOLD" "$five_int" "$R"
    reset=$(format_reset "$FIVE_RESET")
    [[ -n "$reset" ]] && printf ' (♻️ %s)' "$reset"
  fi

  if [[ -n "$FIVE_PCT" && -n "$SEVEN_PCT" ]]; then
    printf ' %s|%s ' "$DIM" "$R"
  fi

  if [[ -n "$SEVEN_PCT" ]]; then
    seven_int=${SEVEN_PCT%.*}
    printf '7d %s%s%%%s' "$(pct_color "$seven_int")$BOLD" "$seven_int" "$R"
    reset=$(format_reset "$SEVEN_RESET")
    [[ -n "$reset" ]] && printf ' (♻️ %s)' "$reset"
  fi

  printf '\n'
fi
