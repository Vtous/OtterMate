import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private var model: AppModel!
    private var statusItem: NSStatusItem!
    private var window: NSWindow?
    private var observation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSRunningApplication.runningApplications(withBundleIdentifier: AppModel.bundleID)
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSRunningApplication.runningApplications(withBundleIdentifier: AppModel.bundleID)
                .first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier })?
                .activate(options: [])
            NSApp.terminate(nil)
            return
        }
        model = AppModel()
        if let url = Bundle.main.url(forResource: "AppIconPreview", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = image
        }
        setupMainMenu()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            image.accessibilityDescription = "OtterMate 水獭头像"
            statusItem.button?.image = image
        }
        statusItem.button?.toolTip = "水獭助手 · 按应用自动切换输入法"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        observation = model.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.updateStatus() }
        }
        updateStatus()
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        let showUpdatedAppearance = UserDefaults.standard.string(forKey: "lastPresentedBuild") != build
        if CommandLine.arguments.contains("--settings") || !model.hasRules || model.errorMessage != nil || showUpdatedAppearance {
            showSettings()
            UserDefaults.standard.set(build, forKey: "lastPresentedBuild")
        }
    }

    private func updateStatus() {
        statusItem.button?.appearsDisabled = !model.configuration.enabled
        statusItem.button?.toolTip = "水獭助手 · \(model.configuration.enabled ? model.currentSourceName : "已暂停")"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.refreshSources()
        menu.removeAllItems()
        let title = NSMenuItem(title: "水獭助手 · OtterMate", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        let current = NSMenuItem(title: "当前输入法：\(model.currentSourceName)", action: nil, keyEquivalent: "")
        current.isEnabled = false
        menu.addItem(current)
        menu.addItem(.separator())
        let toggle = NSMenuItem(title: model.configuration.enabled ? "暂停自动切换" : "开启自动切换", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        if let app = model.activeApp {
            let add = NSMenuItem(title: "为“\(app.name)”添加规则…", action: #selector(addActive), keyEquivalent: "")
            add.target = self
            menu.addItem(add)
        }
        let settings = NSMenuItem(title: "应用规则与设置…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出水獭助手", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    @objc private func toggleEnabled() { model.setEnabled(!model.configuration.enabled) }
    @objc private func addActive() { model.addActiveApp(); showSettings() }

    @objc func showSettings() {
        if window == nil {
            let content = NSHostingView(rootView: SettingsView(model: model))
            let created = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 860, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            created.title = "水獭助手 · OtterMate"
            created.contentView = content
            created.minSize = NSSize(width: 800, height: 680)
            created.isReleasedWhenClosed = false
            created.delegate = self
            created.setFrameAutosaveName("AppInputSwitcherSettings")
            created.center()
            window = created
        }
        model.refreshSources()
        model.refreshLoginStatus()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) { NSApp.setActivationPolicy(.accessory) }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func setupMainMenu() {
        let menu = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于水獭助手", action: #selector(showAbout), keyEquivalent: "").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "隐藏水獭助手", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "退出水獭助手", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let edit = NSMenu(title: "编辑")
        for (title, action, key) in [
            ("撤销", "undo:", "z"), ("剪切", "cut:", "x"), ("复制", "copy:", "c"),
            ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")
        ] { edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key) }
        let editItem = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        editItem.submenu = edit
        menu.addItem(editItem)
        NSApp.mainMenu = menu
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "水獭助手 · OtterMate",
            .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
            .credits: NSAttributedString(string: "按应用自动切换输入法\n本地运行，无网络功能，无按键内容采集\nMIT 开源许可")
        ])
    }
}

MainActor.assumeIsolated {
if CommandLine.arguments.contains("--list-sources") {
    let list = InputSources.list().map { ["id": $0.id, "name": $0.name, "current": $0.id == InputSources.currentID() ? "true" : "false"] }
    if let data = try? JSONSerialization.data(withJSONObject: list, options: [.prettyPrinted, .sortedKeys]),
       let output = String(data: data, encoding: .utf8) { print(output) }
} else {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
}
