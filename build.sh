#!/bin/bash
# 养鱼桌面 Pond Pets · 命令行构建脚本（不想用 Xcode 时用这个）
#
# 前置条件：装有 Xcode 命令行工具。没装的话先执行：
#     xcode-select --install
#
# 用法：
#     ./build.sh          构建到 build/PondPets.app
#     ./build.sh run      构建并立即运行
#
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="PondPets"
SRC_DIR="PondPets"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

if ! xcrun --find swiftc >/dev/null 2>&1; then
    echo "✗ 找不到 swiftc。请先安装 Xcode 命令行工具：xcode-select --install"
    exit 1
fi

echo "→ 编译 Swift…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

SDK_PATH="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"

xcrun swiftc -O \
    -sdk "$SDK_PATH" \
    -target "${ARCH}-apple-macos13.0" \
    -framework Cocoa -framework WebKit -framework ServiceManagement \
    "$SRC_DIR/main.swift" \
    "$SRC_DIR/AppDelegate.swift" \
    "$SRC_DIR/WallpaperWindow.swift" \
    "$SRC_DIR/StatusMenuController.swift" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "→ 组装 App 包…"
cp "$SRC_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$SRC_DIR/pond-wallpaper.html" "$APP_BUNDLE/Contents/Resources/pond-wallpaper.html"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

echo "→ 临时签名（ad-hoc）…"
codesign --force --sign - --timestamp=none "$APP_BUNDLE" >/dev/null 2>&1 \
    || echo "  （签名跳过了，一般不影响本机运行）"

echo "✅ 构建完成：$APP_BUNDLE"

if [[ "${1:-}" == "run" ]]; then
    echo "→ 启动…（菜单栏右侧会出现 🐟）"
    open "$APP_BUNDLE"
fi
