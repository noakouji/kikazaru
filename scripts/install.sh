#!/bin/bash
# Kikazaru をインストールし、ログイン時に自動起動するよう登録する。
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Kikazaru"
INSTALL_DIR="/Applications"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"
LABEL="com.noplan.kikazaru"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/$APP_NAME"

echo "▶ ビルド"
./scripts/build-app.sh release >/dev/null

echo "▶ 既存を停止"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
sleep 1

echo "▶ $INSTALL_DIR へインストール"
rm -rf "$APP_PATH"
cp -R "build/$APP_NAME.app" "$APP_PATH"

echo "▶ ログイン時の自動起動を登録"
mkdir -p "$LOG_DIR" "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_PATH/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <!-- 異常終了したときだけ再起動する。メニューから終了したときは復活させない。 -->
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <!-- 画面を持つアプリなので Interactive を指定する -->
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/stderr.log</string>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo
echo "✅ インストール完了"
echo "   アプリ  : $APP_PATH"
echo "   自動起動: $PLIST"
echo "   ログ    : $LOG_DIR"
echo
echo "   停止したいとき: ./scripts/uninstall.sh"
