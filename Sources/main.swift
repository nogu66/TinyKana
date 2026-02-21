import Cocoa

// MARK: - キー定数
// 左 Command キー単体 → 英数(keyCode: 102)
// 右 Command キー単体 → かな(keyCode: 104)
let leftCmdKeyCode: CGKeyCode  = 55
let rightCmdKeyCode: CGKeyCode = 54
let eisuKeyCode: CGKeyCode     = 102
let kanaKeyCode: CGKeyCode     = 104

let modifierMasks: [CGKeyCode: CGEventFlags] = [
    54: .maskCommand, // 右 Cmd
    55: .maskCommand, // 左 Cmd
    56: .maskShift,
    60: .maskShift,
    59: .maskControl,
    62: .maskControl,
    58: .maskAlternate,
    61: .maskAlternate,
    63: .maskSecondaryFn,
]

// MARK: - キー監視

class KeyWatcher {
    /// 最後に単独で押されたモディファイアキーコード（他のキーが押されるとリセット）
    var pendingKeyCode: CGKeyCode? = nil
    var eventTap: CFMachPort? = nil

    func start() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as NSDictionary
        if AXIsProcessTrustedWithOptions(options) {
            setupEventTap()
        } else {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self?.setupEventTap()
                }
            }
        }
    }

    private func setupEventTap() {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
                              | (1 << CGEventType.keyUp.rawValue)
                              | (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                let watcher = Unmanaged<KeyWatcher>.fromOpaque(refcon!).takeUnretainedValue()
                return watcher.handle(type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            print("TinyKana: イベントタップの作成に失敗しました")
            exit(1)
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // macOS がタイムアウトでタップを無効化した場合は即座に再有効化
        // kCGEventTapDisabledByTimeout = 0xFFFFFFFE, kCGEventTapDisabledByUserInput = 0xFFFFFFFF
        if type.rawValue == 0xFFFFFFFE || type.rawValue == 0xFFFFFFFF {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        switch type {
        case .flagsChanged:
            guard let mask = modifierMasks[keyCode] else {
                return .passUnretained(event)
            }
            let isDown = event.flags.rawValue & mask.rawValue != 0
            if isDown {
                pendingKeyCode = keyCode
            } else {
                // 単独でそのキーを押して離した場合のみ変換を発火
                if pendingKeyCode == keyCode {
                    fireConversion(for: keyCode)
                }
                pendingKeyCode = nil
            }

        case .keyDown, .keyUp:
            // 他のキーが押されたらモディファイア単独押しをキャンセル
            pendingKeyCode = nil

        default:
            break
        }

        return .passUnretained(event)
    }

    private func fireConversion(for keyCode: CGKeyCode) {
        let outputKeyCode: CGKeyCode
        switch keyCode {
        case leftCmdKeyCode:  outputKeyCode = eisuKeyCode
        case rightCmdKeyCode: outputKeyCode = kanaKeyCode
        default: return
        }
        postKey(outputKeyCode)
    }

    private func postKey(_ keyCode: CGKeyCode) {
        CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)?
            .post(tap: .cgSessionEventTap)
        CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)?
            .post(tap: .cgSessionEventTap)
    }
}

// MARK: - アプリデリゲート

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let watcher = KeyWatcher()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        watcher.start()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "⌘"

        let menu = NSMenu()
        menu.addItem(withTitle: "TinyKana", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - エントリーポイント

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Dock に表示しない
let delegate = AppDelegate()
app.delegate = delegate
app.run()
