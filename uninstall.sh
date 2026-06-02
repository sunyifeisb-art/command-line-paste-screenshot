#!/bin/zsh
set -euo pipefail

APP_NAME="option-e-clipboard-path"
PLIST="$HOME/Library/LaunchAgents/io.github.command-line-paste-screenshot.$APP_NAME.plist"

launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
rm -f "$PLIST"
rm -f "$HOME/.local/bin/$APP_NAME"
rm -rf "$HOME/.local/share/$APP_NAME"
rm -rf "$HOME/Applications/OptionEClipboardPath.app"

echo "已卸载 Option+E 剪贴板路径输出脚本。"
