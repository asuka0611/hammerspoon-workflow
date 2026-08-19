#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.hammerspoon"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ -d "$DEST" ]; then
  BACKUP="$HOME/.hammerspoon-backup-$STAMP"
  echo "既存設定をバックアップ: $BACKUP"
  cp -R "$DEST" "$BACKUP"
fi

mkdir -p "$DEST/common" "$DEST/comic" "$DEST/terminal" "$DEST/window"

cp "$ROOT/init.lua" "$DEST/init.lua"
cp "$ROOT/common/key_sequence.lua" "$DEST/common/key_sequence.lua"
cp "$ROOT/comic/hotkeys.lua" "$DEST/comic/hotkeys.lua"
cp "$ROOT/terminal/capture.lua" "$DEST/terminal/capture.lua"
cp "$ROOT/window/focus.lua" "$DEST/window/focus.lua"

echo "インストール完了"
echo "Hammerspoonで Reload Config を実行してください。"
