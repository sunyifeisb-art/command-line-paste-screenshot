import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

final class OptionEClipboardPath {
    static let shared = OptionEClipboardPath()

    private let screenshotDir = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Pictures")
        .appendingPathComponent("截图")
    private let logURL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".local")
        .appendingPathComponent("share")
        .appendingPathComponent("option-e-clipboard-path")
        .appendingPathComponent("events.log")

    private init() {}

    func start() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            log("辅助功能权限未生效")
            fputs("请在 系统设置 -> 隐私与安全性 -> 辅助功能 里允许 option-e-clipboard-path，然后重新启动它。\n", stderr)
            RunLoop.current.run()
            return
        }
        log("辅助功能权限已生效，准备监听快捷键")

        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: nil
        ) else {
            log("无法创建全局快捷键监听")
            fputs("无法创建全局快捷键监听。请确认已授予辅助功能权限。\n", stderr)
            exit(1)
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("option-e-clipboard-path 已启动。按 Option+E 输出剪贴板文件路径/截图路径/文本。")
        RunLoop.current.run()
    }

    func handleHotkey() {
        DispatchQueue.main.async {
            self.log("收到 Option/Command+E")
            guard let output = self.clipboardOutput(), !output.isEmpty else {
                self.log("剪贴板没有可输出内容")
                NSSound.beep()
                return
            }
            self.log("输出：\(output)")
            self.pasteText(output)
        }
    }

    func handleCopySelectedFinderPath() {
        DispatchQueue.main.async {
            self.log("收到 Option+R")
            guard let output = self.selectedFinderPaths(), !output.isEmpty else {
                self.log("Finder 没有选中文件")
                NSSound.beep()
                return
            }

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(output, forType: .string)
            self.log("已复制 Finder 选中文件路径：\(output)")
        }
    }

    func printOnceAndExit() {
        guard let output = clipboardOutput(), !output.isEmpty else {
            exit(2)
        }
        print(output)
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let line = "[\(formatter.string(from: Date()))] \(message)\n"

        do {
            try FileManager.default.createDirectory(
                at: logURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: logURL.path),
               let handle = try? FileHandle(forWritingTo: logURL) {
                try handle.seekToEnd()
                try handle.write(contentsOf: Data(line.utf8))
                try handle.close()
            } else {
                try Data(line.utf8).write(to: logURL)
            }
        } catch {
            fputs("写日志失败：\(error)\n", stderr)
        }
    }

    private func clipboardOutput() -> String? {
        let pasteboard = NSPasteboard.general

        if let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty {
            return urls.map(\.path).joined(separator: "\n")
        }

        if let fileURLText = pasteboard.string(forType: NSPasteboard.PasteboardType("public.file-url")) {
            let paths = fileURLText
                .split(whereSeparator: \.isNewline)
                .compactMap { URL(string: String($0))?.path.removingPercentEncoding }
            if !paths.isEmpty {
                return paths.joined(separator: "\n")
            }
        }

        if let image = NSImage(pasteboard: pasteboard), let savedPath = saveImageAsPNG(image) {
            return savedPath
        }

        return pasteboard.string(forType: .string)
    }

    private func selectedFinderPaths() -> String? {
        let source = """
        tell application "Finder"
            set selectedItems to selection
            if selectedItems is {} then return ""
            set pathList to {}
            repeat with selectedItem in selectedItems
                set end of pathList to POSIX path of (selectedItem as alias)
            end repeat
            set AppleScript's text item delimiters to linefeed
            set joinedPaths to pathList as text
            set AppleScript's text item delimiters to ""
            return joinedPaths
        end tell
        """

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return nil
        }

        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            log("读取 Finder 选中文件失败：\(errorInfo)")
            return nil
        }

        return result.stringValue
    }

    private func saveImageAsPNG(_ image: NSImage) -> String? {
        do {
            try FileManager.default.createDirectory(at: screenshotDir, withIntermediateDirectories: true)
        } catch {
            fputs("创建截图目录失败：\(error)\n", stderr)
            return nil
        }

        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let filename = "截图-\(formatter.string(from: Date())).png"
        let destinationURL = screenshotDir.appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return destinationURL.path
    }

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let source = CGEventSource(stateID: .hidSystemState)
        let commandVDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        commandVDown?.flags = .maskCommand
        commandVDown?.post(tap: .cghidEventTap)

        let commandVUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        commandVUp?.flags = .maskCommand
        commandVUp?.post(tap: .cghidEventTap)
    }
}

private let eventCallback: CGEventTapCallBack = { _, type, event, _ in
    guard type == .keyDown else {
        return Unmanaged.passUnretained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    let optionOnly = flags.contains(.maskAlternate)
        && !flags.contains(.maskCommand)
        && !flags.contains(.maskControl)
    let commandE = flags.contains(.maskCommand)
        && !flags.contains(.maskAlternate)
        && !flags.contains(.maskControl)

    if keyCode == 14 && (optionOnly || commandE) {
        OptionEClipboardPath.shared.handleHotkey()
        return nil
    }

    if keyCode == 15 && optionOnly {
        OptionEClipboardPath.shared.handleCopySelectedFinderPath()
        return nil
    }

    return Unmanaged.passUnretained(event)
}

if CommandLine.arguments.contains("--once") {
    OptionEClipboardPath.shared.printOnceAndExit()
} else {
    OptionEClipboardPath.shared.start()
}
