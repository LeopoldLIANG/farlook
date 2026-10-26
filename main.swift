import AppKit
import CoreGraphics

final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var engine = SessionTimer()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var panel: ReminderPanel?
    private var heading: NSTextField!
    private var message: NSTextField!
    private var countdown: NSTextField!
    private var primaryButton: NSButton!
    private var laterButton: NSButton!
    private var sessionInactive = false
    private var screenAsleep = false
    private var systemAsleep = false
    private var locked = false
    private var completedUntil: TimeInterval?
    private var previewVisible = false
    private var statusLine: NSMenuItem!
    private var idleLine: NSMenuItem!
    private var ruleItems: [NSMenuItem] = []
    private var pauseItem: NSMenuItem!
    private let defaults = UserDefaults.standard
    private let demoMode = CommandLine.arguments.contains("--demo")
    private let smokeMode = CommandLine.arguments.contains("--smoke-test")
    private var idleSeconds: TimeInterval {
        // kCGAnyInputEventType = UINT32_MAX. .null measures null events, not all input.
        let allInput = CGEventType(rawValue: UInt32.max)!
        let value = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: allInput)
        return value.isFinite && value >= 0 ? value : 0
    }
    private var unavailable: Bool { sessionInactive || screenAsleep || systemAsleep || locked }

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: ["sound": true])
        // Prevent duplicate menu bar timers when the bundle is launched twice.
        if let bundleID = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        let rule = defaults.object(forKey: "idleMinutes") as? Int ?? 2
        engine.idleReset = rule == 0 ? nil : Double(rule * 60)
        engine.reset()
        setupMenu()
        observeSystem()
        timer = Timer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
        refreshStatus()
        if demoMode { showReminder() }
        if smokeMode {
            print("FarLook smoke test: idleSeconds=\(idleSeconds), menuItems=\(statusItem.menu!.items.count)")
            showReminder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.beginRest() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("FarLook smoke test: phase=\(self.engine.phase), restRemaining=\(self.engine.restRemaining), idleSeconds=\(self.idleSeconds), idleReset=\(String(describing: self.engine.idleReset))")
                NSApp.terminate(nil)
            }
        }
    }

    private func item(_ title: String, action: Selector? = nil) -> NSMenuItem {
        let result = NSMenuItem(title: title, action: action, keyEquivalent: "")
        result.target = self
        return result
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "远眺一下")
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }
        let menu = NSMenu()
        menu.autoenablesItems = false
        statusLine = item("")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        idleLine = item("")
        idleLine.isEnabled = false
        menu.addItem(idleLine)
        menu.addItem(.separator())
        menu.addItem(item("现在休息 30 秒…", action: #selector(restNow)))
        menu.addItem(item("预览提醒…", action: #selector(previewReminder)))
        menu.addItem(item("重新开始 30 分钟计时", action: #selector(resetSession)))
        pauseItem = item("暂停提醒", action: #selector(togglePause))
        menu.addItem(pauseItem)
        menu.addItem(.separator())
        let ruleMenu = NSMenu()
        for (minutes, title) in [(2, "无操作满 2 分钟重置"), (5, "无操作满 5 分钟重置"),
                                  (10, "无操作满 10 分钟重置"), (0, "仅锁屏／睡眠或休息后重置")] {
            let entry = item(title, action: #selector(changeRule(_:)))
            entry.tag = minutes
            ruleItems.append(entry)
            ruleMenu.addItem(entry)
        }
        let rules = item("连续使用的判定")
        rules.submenu = ruleMenu
        menu.addItem(rules)
        let sound = item("提醒及休息结束时播放提示音", action: #selector(toggleSound(_:)))
        sound.state = defaults.bool(forKey: "sound") ? .on : .off
        menu.addItem(sound)
        menu.addItem(item("说明与计时规则…", action: #selector(showHelp)))
        menu.addItem(.separator())
        let quit = item("退出远眺一下", action: #selector(quitApp))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
        statusItem.menu = menu
        updateRuleChecks()
    }

    private func observeSystem() {
        let nc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification,
                     NSWorkspace.screensDidSleepNotification, NSWorkspace.screensDidWakeNotification,
                     NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            nc.addObserver(self, selector: #selector(workspaceChanged(_:)), name: name, object: nil)
        }
        // These lock notifications are system conventions, not a public AppKit API.
        // Public workspace sleep/session events and the idle rule provide fallbacks.
        let dc = DistributedNotificationCenter.default()
        dc.addObserver(self, selector: #selector(screenLocked), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dc.addObserver(self, selector: #selector(screenUnlocked), name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    @objc private func workspaceChanged(_ note: Notification) {
        switch note.name {
        case NSWorkspace.willSleepNotification: systemAsleep = true
        case NSWorkspace.didWakeNotification: systemAsleep = false
        case NSWorkspace.screensDidSleepNotification: screenAsleep = true
        case NSWorkspace.screensDidWakeNotification: screenAsleep = false
        case NSWorkspace.sessionDidResignActiveNotification: sessionInactive = true
        case NSWorkspace.sessionDidBecomeActiveNotification: sessionInactive = false
        default: break
        }
        resetForAbsence()
    }
    @objc private func screenLocked() { locked = true; resetForAbsence() }
    @objc private func screenUnlocked() { locked = false; resetForAbsence() }

    private func resetForAbsence() {
        let wasPaused = engine.phase == .paused
        engine.reset()
        if wasPaused { engine.setPaused(true) }
        panel?.orderOut(nil)
        completedUntil = nil
        refreshStatus()
    }

    @objc private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let oldPhase = engine.phase
        if engine.tick(now: now, idle: idleSeconds, unavailable: unavailable) { showReminder() }
        if engine.didCompleteRest {
            completedUntil = now + 6
            heading.stringValue = "30 秒结束了"
            message.stringValue = "准备好后，再继续手头的工作。"
            countdown.stringValue = "✓"
            primaryButton.title = "继续工作"
            primaryButton.isEnabled = true
            laterButton.isHidden = true
            if defaults.bool(forKey: "sound") { NSSound(named: "Glass")?.play() }
        } else if oldPhase != .working && oldPhase != .paused && engine.phase == .working {
            panel?.orderOut(nil)
        }
        if engine.phase == .resting {
            countdown.stringValue = "\(Int(ceil(engine.restRemaining)))"
        }
        if let end = completedUntil, now >= end { panel?.orderOut(nil); completedUntil = nil }
        refreshStatus()
    }

    private func refreshStatus() {
        let remaining = max(0, Int(ceil(engine.workInterval - engine.elapsed)))
        let time = String(format: "%02d:%02d", remaining / 60, remaining % 60)
        switch engine.phase {
        case .working:
            statusItem.button?.title = " \(time)"
            statusLine.title = engine.waitingForInput ? "等待操作，开始新一轮 30 分钟" : "距离远眺提醒还有 \(time)"
        case .reminder:
            statusItem.button?.title = " 休息"
            statusLine.title = "已满 30 分钟，等待开始休息"
        case .resting:
            statusItem.button?.title = " \(Int(ceil(engine.restRemaining)))s"
            statusLine.title = "远眺休息中"
        case .paused:
            statusItem.button?.title = " 暂停"
            statusLine.title = "提醒已暂停"
        }
        statusItem.button?.toolTip = "远眺一下 · \(statusLine.title)"
        let rule = engine.idleReset.map { "无操作满 \(Int($0 / 60)) 分钟重置" } ?? "阅读／视频持续计时"
        idleLine.title = "\(rule) · 锁屏／睡眠重置"
        pauseItem.title = engine.phase == .paused ? "恢复提醒（新一轮计时）" : "暂停提醒"
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor = .labelColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.alignment = .center
        field.maximumNumberOfLines = 0
        field.lineBreakMode = .byWordWrapping
        return field
    }

    private func ensurePanel() {
        guard panel == nil else { return }
        let p = ReminderPanel(contentRect: NSRect(x: 0, y: 0, width: 440, height: 330),
                              styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                              backing: .buffered, defer: false)
        p.title = "远眺一下"
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isFloatingPanel = true
        p.level = .floating
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = true
        p.backgroundColor = .windowBackgroundColor
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 330))
        p.contentView = view
        heading = label("该远眺一下了", size: 25, weight: .semibold)
        heading.frame = NSRect(x: 20, y: 265, width: 400, height: 40)
        message = label("已连续使用电脑 30 分钟。\n把视线移向远处，休息 30 秒。", size: 15, weight: .regular, color: .secondaryLabelColor)
        message.frame = NSRect(x: 30, y: 205, width: 380, height: 50)
        countdown = label("30", size: 68, weight: .light, color: .systemTeal)
        countdown.font = .monospacedDigitSystemFont(ofSize: 68, weight: .light)
        countdown.frame = NSRect(x: 40, y: 108, width: 360, height: 88)
        primaryButton = NSButton(title: "开始 30 秒休息", target: self, action: #selector(primaryAction))
        primaryButton.bezelStyle = .rounded
        primaryButton.controlSize = .large
        primaryButton.frame = NSRect(x: 110, y: 63, width: 220, height: 38)
        // No global hotkey or default Return binding: work keystrokes should not dismiss it.
        laterButton = NSButton(title: "5 分钟后提醒", target: self, action: #selector(snooze))
        laterButton.bezelStyle = .rounded
        laterButton.frame = NSRect(x: 95, y: 22, width: 250, height: 28)
        for element in [heading!, message!, countdown!, primaryButton!, laterButton!] as [NSView] { view.addSubview(element) }
        panel = p
    }

    private func showReminder(preview: Bool = false) {
        ensurePanel()
        previewVisible = preview || demoMode
        completedUntil = nil
        heading.stringValue = preview || demoMode ? "远眺提醒预览" : "该远眺一下了"
        message.stringValue = preview || demoMode ? "正式提醒将在连续使用满 30 分钟后出现。\n把视线移向远处，休息 30 秒。" : "已连续使用电脑 30 分钟。\n把视线移向远处，休息 30 秒。"
        countdown.stringValue = "30"
        primaryButton.title = "开始 30 秒休息"
        primaryButton.isEnabled = true
        laterButton.title = previewVisible ? "关闭预览" : "5 分钟后提醒"
        laterButton.isHidden = false
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main {
            let frame = screen.visibleFrame
            panel?.setFrameOrigin(NSPoint(x: frame.midX - 220, y: frame.midY - 165))
        }
        panel?.orderFrontRegardless()
        if !preview && !demoMode && defaults.bool(forKey: "sound") { NSSound(named: "Glass")?.play() }
    }

    @objc private func primaryAction() {
        if completedUntil != nil { panel?.orderOut(nil); completedUntil = nil; return }
        beginRest()
    }
    @objc private func beginRest() {
        previewVisible = false
        engine.startRest(now: ProcessInfo.processInfo.systemUptime)
        heading.stringValue = "让视线停在远处"
        message.stringValue = "现在可以移开视线。\n倒计时结束后，再继续工作。"
        primaryButton.title = "休息中…"
        primaryButton.isEnabled = false
        laterButton.title = "取消休息，5 分钟后提醒"
        refreshStatus()
    }
    @objc private func restNow() { showReminder(preview: true); beginRest() }
    @objc private func previewReminder() { showReminder(preview: true) }
    @objc private func snooze() {
        if !previewVisible { engine.snooze() }
        previewVisible = false
        completedUntil = nil
        panel?.orderOut(nil)
        refreshStatus()
    }
    @objc private func resetSession() { engine.reset(); panel?.orderOut(nil); completedUntil = nil; refreshStatus() }
    @objc private func togglePause() { engine.setPaused(engine.phase != .paused); panel?.orderOut(nil); completedUntil = nil; refreshStatus() }
    @objc private func changeRule(_ sender: NSMenuItem) {
        defaults.set(sender.tag, forKey: "idleMinutes")
        engine.idleReset = sender.tag == 0 ? nil : Double(sender.tag * 60)
        resetSession()
        updateRuleChecks()
    }
    private func updateRuleChecks() {
        let selected = engine.idleReset.map { Int($0 / 60) } ?? 0
        for entry in ruleItems { entry.state = entry.tag == selected ? .on : .off }
    }
    @objc private func toggleSound(_ sender: NSMenuItem) {
        let enabled = sender.state != .on
        defaults.set(enabled, forKey: "sound")
        sender.state = enabled ? .on : .off
    }
    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "远眺一下 · 计时规则"
        alert.informativeText = "每轮 30 分钟包含键鼠短暂停顿。默认无操作满 2 分钟后清零，恢复操作再开始。读长文或看视频时，静止超过阈值同样会清零。可在菜单修改阈值，或选择阅读／看视频始终计时。\n\n锁屏、系统睡眠、屏幕休眠或切换用户后清零。暂停、退出期间不计时；恢复或重新打开后开始新一轮。\n\n满 30 分钟显示提醒；点击开始后倒计时 30 秒，结束时播放提示音（可关闭），也可推迟 5 分钟。倒计时只表示时间经过，不能确认是否远眺。\n\n仅本地读取无操作时长和系统状态，不读取键盘内容，不使用摄像头，不联网。无需辅助功能或屏幕录制权限。\n\n菜单栏显示剩余时间。此版本需手动打开，未设置开机自启。"
        alert.addButton(withTitle: "知道了")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    @objc private func quitApp() { NSApp.terminate(nil) }
}

let application = NSApplication.shared
application.setActivationPolicy(.accessory)
let delegate = AppDelegate()
application.delegate = delegate
application.run()
