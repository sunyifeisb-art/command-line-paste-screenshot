# 命令行粘贴截图

一个 macOS 后台快捷键小工具，用来把剪贴板里的文件、截图或文本转换成可直接粘贴/输入的内容。

适合自己安装，也适合直接交给 Codex、Claude Code、OpenCode 等本地 agent 帮你部署。

## 功能

- Finder 里复制文件或文件夹后，按 `Option+E`：在当前光标处输出真实路径。
- 截图复制到剪贴板后，按 `Option+E`：自动保存到 `~/Pictures/截图`，并在当前光标处输出保存后的 PNG 路径。
- 剪贴板是普通文本时，按 `Option+E`：直接输出那段文本。
- Finder 里选中文件或文件夹后，按 `Option+R`：把选中项路径复制到剪贴板，不自动输出。

## 让 Agent 帮你部署

把下面这段话发给你的本地编程 agent：

```text
请帮我安装这个 macOS 快捷键工具：
https://github.com/sunyifeisb-art/command-line-paste-screenshot

要求：
1. clone 仓库
2. 运行 ./install.sh
3. 确认 LaunchAgent 已启动
4. 提醒我在「系统设置 -> 隐私与安全性 -> 辅助功能」里授权 OptionEClipboardPath
5. 如果我要用 Option+R，提醒我第一次弹出控制 Finder 时点允许
6. 授权后帮我重启服务：
   launchctl kickstart -k gui/$(id -u)/io.github.command-line-paste-screenshot.option-e-clipboard-path
```

Agent 不需要把脚本复制到固定用户名路径里。安装脚本会自动使用当前用户的 `$HOME`，不同 macOS 用户都能适配。

## 手动安装

```zsh
git clone https://github.com/sunyifeisb-art/command-line-paste-screenshot.git
cd command-line-paste-screenshot
./install.sh
```

安装脚本会：

- 编译 Swift 源码
- 生成 `~/Applications/OptionEClipboardPath.app`
- 创建截图保存目录 `~/Pictures/截图`
- 注册 LaunchAgent，让它登录后自动在后台运行

## 权限授权

macOS 会拦截全局快捷键监听、自动粘贴和读取 Finder 选中项，所以第一次使用必须授权。

1. 打开「系统设置」->「隐私与安全性」->「辅助功能」
2. 打开 `OptionEClipboardPath` 的开关
3. 如果 `Option+R` 第一次触发时提示控制 Finder，选择允许
4. 授权后运行：

```zsh
launchctl kickstart -k gui/$(id -u)/io.github.command-line-paste-screenshot.option-e-clipboard-path
```

不同用户会安装到各自的 `$HOME` 下，不依赖固定用户名。macOS 权限也按本机应用身份单独授权：如果更新后快捷键没反应，先确认「辅助功能」里的 `OptionEClipboardPath` 开关已打开，再执行上面的重启命令。

## 使用

### 输出 Finder 已复制文件/文件夹路径

1. 在 Finder 复制一个文件或文件夹
2. 切到任意输入框
3. 按 `Option+E`
4. 当前输入框会出现文件或文件夹的完整路径

### 保存剪贴板截图并输出路径

1. 用系统截图工具把截图复制到剪贴板
2. 切到任意输入框
3. 按 `Option+E`
4. 图片会保存到 `~/Pictures/截图`
5. 当前输入框会出现刚保存的 PNG 文件路径

如果电脑里还没有 `~/Pictures/截图`，安装脚本会自动创建；即使安装时没创建，第一次保存截图时程序也会自动创建。

### 输出普通文本

1. 剪贴板里复制一段普通文本
2. 切到任意输入框
3. 按 `Option+E`
4. 当前输入框会出现那段文本

### 复制 Finder 选中项路径到剪贴板

1. 在 Finder 选中文件或文件夹，不需要按复制
2. 按 `Option+R`
3. 完整路径会被复制到剪贴板
4. 你可以自己 `Command+V` 粘贴

多选文件或文件夹时，会按行复制多个路径。

## 检查运行状态

```zsh
launchctl print gui/$(id -u)/io.github.command-line-paste-screenshot.option-e-clipboard-path
pgrep -x OptionEClipboardPath
```

如果看到 `state = running` 或能看到 `OptionEClipboardPath` 进程，说明后台服务在运行。

## 重启服务

```zsh
launchctl kickstart -k gui/$(id -u)/io.github.command-line-paste-screenshot.option-e-clipboard-path
```

## 卸载

```zsh
./uninstall.sh
```

## 日志

运行日志在：

```text
~/.local/share/option-e-clipboard-path/events.log
```

如果快捷键没反应，先看这个日志有没有出现“收到 Option+R”或“收到 Option/Command+E”。

## 常见问题

### 授权了还是没反应

确认「辅助功能」里打开的是 `OptionEClipboardPath`，不是只有旧的命令行条目。授权后执行：

```zsh
launchctl kickstart -k gui/$(id -u)/io.github.command-line-paste-screenshot.option-e-clipboard-path
```

### Option+R 不能读取 Finder 选中文件

第一次触发时 macOS 可能会弹出“允许控制 Finder”的提示，需要点允许。也可以到「系统设置 -> 隐私与安全性 -> 自动化」里检查 `OptionEClipboardPath` 是否允许控制 Finder。

### 会不会费电

平时只是在后台等待快捷键事件，正常 CPU 接近 `0%`，内存通常只有几 MB。

### 安装在哪里

默认安装到当前用户目录：

```text
~/Applications/OptionEClipboardPath.app
~/.local/bin/option-e-clipboard-path
~/.local/share/option-e-clipboard-path
~/Library/LaunchAgents/io.github.command-line-paste-screenshot.option-e-clipboard-path.plist
```

## 协议

MIT
