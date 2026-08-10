#!/bin/bash
# 自動起動を解除し、アプリを取り除く。
set -euo pipefail

APP_NAME="Kikazaru"
LABEL="com.noplan.kikazaru"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "▶ 自動起動を解除"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"

echo "▶ アプリを終了"
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true

echo "▶ アプリを削除"
rm -rf "/Applications/$APP_NAME.app"

echo "✅ 削除しました（設定は残ります）"
echo "   設定も消す場合: defaults delete $LABEL"
