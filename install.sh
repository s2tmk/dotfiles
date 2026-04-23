#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles/.claude"
TARGET_DIR="$HOME/.claude"

if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Error: $DOTFILES_DIR が見つかりません" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 | while read -r file; do
  filename="$(basename "$file")"
  target="$TARGET_DIR/$filename"

  if [ -L "$target" ]; then
    echo "skip (既存のシンボリックリンク): $target"
    continue
  fi

  if [ -e "$target" ]; then
    echo "backup: $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi

  ln -s "$file" "$target"
  echo "link: $file -> $target"
done

echo "完了"
