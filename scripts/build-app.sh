#!/bin/bash
# SoundDuck.app を組み立てる。Xcode プロジェクトを使わずターミナルで完結させる。
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP="build/SoundDuck.app"

echo "▶ ビルド ($CONFIG)"
swift build -c "$CONFIG"

echo "▶ .app を組み立て"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/SoundDuck" "$APP/Contents/MacOS/SoundDuck"
cp Resources/Info.plist "$APP/Contents/Info.plist"

echo "▶ 署名（ローカル実行用のad-hoc署名）"
codesign --force --deep --sign - "$APP"

echo "✅ $APP"
echo "   起動: open $APP"
