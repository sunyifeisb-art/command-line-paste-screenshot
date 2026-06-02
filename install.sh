#!/bin/zsh
set -euo pipefail

APP_NAME="option-e-clipboard-path"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/Applications/OptionEClipboardPath.app"
APP_CONTENTS="$APP_DIR/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
PLIST="$LAUNCH_AGENTS/com.xiangyang.$APP_NAME.plist"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SWIFT="$SOURCE_DIR/$APP_NAME.swift"
BIN="$BIN_DIR/$APP_NAME"
APP_BIN="$APP_MACOS/OptionEClipboardPath"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$APP_MACOS" "$LAUNCH_AGENTS"
cp "$SOURCE_SWIFT" "$INSTALL_DIR/$APP_NAME.swift"

xcrun swiftc "$INSTALL_DIR/$APP_NAME.swift" \
  -framework AppKit \
  -framework ApplicationServices \
  -framework CoreGraphics \
  -framework Foundation \
  -framework ImageIO \
  -o "$BIN"

chmod +x "$BIN"
cp "$BIN" "$APP_BIN"
chmod +x "$APP_BIN"

cat > "$APP_CONTENTS/Info.plist" <<APPPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>OptionEClipboardPath</string>
  <key>CFBundleIdentifier</key>
  <string>com.xiangyang.option-e-clipboard-path</string>
  <key>CFBundleName</key>
  <string>OptionEClipboardPath</string>
  <key>CFBundleDisplayName</key>
  <string>option-e-clipboard-path</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSBackgroundOnly</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>读取 Finder 当前选中文件或文件夹的路径。</string>
</dict>
</plist>
APPPLIST

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.xiangyang.$APP_NAME</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP_BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$INSTALL_DIR/stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$INSTALL_DIR/stderr.log</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
pgrep -x OptionEClipboardPath >/dev/null 2>&1 && pkill -x OptionEClipboardPath || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/com.xiangyang.$APP_NAME"

cat <<MSG
已安装并启动 Option+E 剪贴板路径输出脚本。

如果第一次按 Option+E 没反应：
1. 打开 系统设置 -> 隐私与安全性 -> 辅助功能
2. 允许 option-e-clipboard-path 或 OptionEClipboardPath
3. 再运行一次这个安装脚本，或注销后重新登录

截图会保存到：
$HOME/Pictures/截图
MSG
