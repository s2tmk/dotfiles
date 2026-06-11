#!/bin/bash
# Symlink every top-level entry of <repo>/.claude into ~/.claude.
#
# Idempotent:
#   - links that already point to the right place are skipped
#   - wrong or dangling symlinks are re-pointed
#   - real files/dirs in the way are backed up to *.bak.<timestamp> first
#
# Runtime state (history, projects/, plugins/, session data, caches) lives
# directly in ~/.claude and is intentionally NOT versioned or linked.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude"
TARGET_DIR="$HOME/.claude"
EXCLUDE=".DS_Store"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: $SOURCE_DIR not found" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

linked=0 relinked=0 skipped=0 backed_up=0

for src in "$SOURCE_DIR"/* "$SOURCE_DIR"/.[!.]*; do
  [ -e "$src" ] || [ -L "$src" ] || continue
  name="$(basename "$src")"
  case " $EXCLUDE " in *" $name "*) continue ;; esac
  target="$TARGET_DIR/$name"

  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$src" ]; then
      echo "ok:      $name (already linked)"
      skipped=$((skipped + 1))
      continue
    fi
    rm "$target"
    ln -s "$src" "$target"
    echo "relink:  $name -> $src"
    relinked=$((relinked + 1))
    continue
  fi

  if [ -e "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "backup:  $name -> $(basename "$backup")"
    backed_up=$((backed_up + 1))
  fi

  ln -s "$src" "$target"
  echo "link:    $name -> $src"
  linked=$((linked + 1))
done

echo "----"
echo "Done: $linked linked, $relinked relinked, $skipped already correct, $backed_up backed up."
echo "Restart Claude Code sessions to pick up config changes (hooks/settings load at session start)."
