# 命令行粘贴截图

一个 macOS 后台快捷键小工具，用来把剪贴板里的文件、截图或文本转换成可直接粘贴/输入的内容。

## 功能

- Finder 里复制文件或文件夹后，按 `Option+E`：在当前光标处输出真实路径。
- 截图复制到剪贴板后，按 `Option+E`：自动保存到 `~/Pictures/截图`，并在当前光标处输出保存后的 PNG 路径。
- 剪贴板是普通文本时，按 `Option+E`：直接输出那段文本。
- Finder 里选中文件或文件夹后，按 `Option+R`：把选中项路径复制到剪贴板，不自动输出。

## 安装

```zsh
git clone https://github.com/sunyifeisb-art/命令行粘贴截图.git
cd 命令行粘贴截图
./install.sh
```

安装脚本会：

- 编译 Swift 源码
- 生成 `~/Applications/OptionEClipboardPath.app`
- 注册 LaunchAgent，让它登录后自动在后台运行

## 首次授权

第一次使用需要在 macOS 里授权：

1. 打开「系统设置」->「隐私与安全性」->「辅助功能」
2. 打开 `OptionEClipboardPath` 的开关
3. 如果 `Option+R` 第一次触发时提示控制 Finder，选择允许
4. 授权后运行：

```zsh
launchctl kickstart -k gui/$(id -u)/com.xiangyang.option-e-clipboard-path
```

## 使用

复制文件路径：

1. 在 Finder 复制一个文件或文件夹
2. 切到任意输入框
3. 按 `Option+E`

保存剪贴板截图并输出路径：

1. 用系统截图工具把截图复制到剪贴板
2. 切到任意输入框
3. 按 `Option+E`

复制 Finder 选中项路径到剪贴板：

1. 在 Finder 选中文件或文件夹
2. 按 `Option+R`
3. 路径已经在剪贴板里

## 卸载

```zsh
./uninstall.sh
```

## 日志

运行日志在：

```text
~/.local/share/option-e-clipboard-path/events.log
```

## 协议

MIT
