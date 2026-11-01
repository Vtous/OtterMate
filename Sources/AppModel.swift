import AppKit
import Combine
import Carbon
import ServiceManagement
import UniformTypeIdentifiers

struct ActiveApplication: Equatable {
    let bundleID: String
    let name: String
    let path: String
}

@MainActor
final class AppModel: ObservableObject {
    static let bundleID = Bundle.main.bundleIdentifier ?? "local.ten.AppInputSwitcher"
    @Published private(set) var configuration = Configuration()
    @Published private(set) var sources: [InputSource] = []
    @Published private(set) var currentSourceID: String? = nil
    @Published private(set) var activeApp: ActiveApplication? = nil
    @Published private(set) var message = "添加应用规则后，切换应用即可自动选择输入法。"
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginRequiresApproval = false
    @Published var searchQuery = ""

    private let store: ConfigurationStore
    private var observers: [NSObjectProtocol] = []
    private var sourceObservers: [NSObjectProtocol] = []
    private var pendingSwitch: Task<Void, Never>?
    private var persistenceBlocked = false

    init(store: ConfigurationStore = .standard) {
        self.store = store
        do { configuration = try store.load() }
        catch {
            configuration.enabled = false
            persistenceBlocked = true
            errorMessage = "原配置无法读取，已暂停切换且保留原文件：\(error.localizedDescription)"
        }
        refreshSources()
        refreshLoginStatus()
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
                    self?.activated(app)
                }
            })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshSources(); self?.applyToFrontmost() }
            })
        for name in [kTISNotifySelectedKeyboardInputSourceChanged, kTISNotifyEnabledKeyboardInputSourcesChanged] {
            sourceObservers.append(DistributedNotificationCenter.default().addObserver(
                forName: Notification.Name(name! as String), object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.refreshSources() }
                })
        }
        if let frontmost = NSWorkspace.shared.frontmostApplication { activated(frontmost) }
    }

    var currentSourceName: String { name(for: currentSourceID) }
    var preferredSourceID: String {
        sources.first(where: { $0.name.contains("豆包") })?.id ?? currentSourceID ?? sources.first?.id ?? ""
    }
    var configURL: URL { store.url }
    var hasRules: Bool { !configuration.rules.isEmpty }

    func name(for id: String?) -> String {
        guard let id else { return "未获取" }
        return sources.first(where: { $0.id == id })?.name ?? "输入法未启用"
    }

    func refreshSources() {
        sources = InputSources.list()
        currentSourceID = InputSources.currentID()
    }

    @discardableResult
    private func commit(_ update: (inout Configuration) -> Void) -> Bool {
        guard !persistenceBlocked else {
            errorMessage = "请先备份并重建无法读取的配置。"
            return false
        }
        var next = configuration
        update(&next)
        do {
            try store.save(next)
            pendingSwitch?.cancel()
            configuration = next
            errorMessage = nil
            return true
        } catch {
            errorMessage = "设置未保存：\(error.localizedDescription)"
            return false
        }
    }

    func setEnabled(_ enabled: Bool) {
        if commit({ $0.enabled = enabled }) {
            message = enabled ? "自动切换已开启，下次进入应用时生效。" : "已暂停，保留所有应用规则。"
        }
    }

    func setDefault(_ id: String) {
        _ = commit { $0.defaultSourceID = id.isEmpty ? nil : id }
    }

    func setRuleSource(_ bundleID: String, _ sourceID: String) {
        _ = commit { config in
            guard let index = config.rules.firstIndex(where: { $0.bundleID == bundleID }) else { return }
            config.rules[index].inputSourceID = sourceID
        }
    }

    func setRuleEnabled(_ bundleID: String, _ enabled: Bool) {
        _ = commit { config in
            guard let index = config.rules.firstIndex(where: { $0.bundleID == bundleID }) else { return }
            config.rules[index].enabled = enabled
        }
    }

    func removeRule(_ bundleID: String) { _ = commit { $0.rules.removeAll { $0.bundleID == bundleID } } }

    func addActiveApp() {
        guard let activeApp else { return }
        add(app: activeApp)
    }

    private func add(app: ActiveApplication) {
        guard app.bundleID != Self.bundleID, !preferredSourceID.isEmpty else { return }
        let sourceID = preferredSourceID
        if commit({ config in
            if let index = config.rules.firstIndex(where: { $0.bundleID == app.bundleID }) {
                config.rules[index].appName = app.name
                config.rules[index].appPath = app.path
                config.rules[index].enabled = true
            } else {
                config.rules.append(AppRule(bundleID: app.bundleID, appName: app.name,
                    appPath: app.path, inputSourceID: sourceID))
            }
            config.rules.sort { $0.appName.localizedStandardCompare($1.appName) == .orderedAscending }
        }) { message = "已添加 \(app.name)，可在右侧选择它的输入法。" }
    }

    func chooseApplications() {
        let panel = NSOpenPanel()
        panel.title = "添加应用规则"
        panel.message = "选择一个或多个应用，为它们指定输入法。"
        panel.prompt = "添加应用"
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else {
                errorMessage = "无法读取应用信息：\(url.lastPathComponent)"; continue
            }
            let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent
            add(app: ActiveApplication(bundleID: id, name: name, path: url.path))
        }
    }

    private func activated(_ app: NSRunningApplication) {
        pendingSwitch?.cancel()
        guard let id = app.bundleIdentifier, id != Self.bundleID, app.activationPolicy == .regular else { return }
        let snapshot = ActiveApplication(bundleID: id, name: app.localizedName ?? id, path: app.bundleURL?.path ?? "")
        activeApp = snapshot
        schedule(snapshot, processID: app.processIdentifier)
    }

    func applyToFrontmost() {
        if let app = NSWorkspace.shared.frontmostApplication { activated(app) }
    }

    private func schedule(_ app: ActiveApplication, processID: pid_t) {
        pendingSwitch = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            guard let self, !Task.isCancelled,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == processID else { return }
            self.refreshSources()
            let decision = RuleResolver.decide(configuration: self.configuration, appID: app.bundleID,
                ownAppID: Self.bundleID, available: Set(self.sources.map(\.id)))
            switch decision {
            case .paused, .unchanged: return
            case .missingSource:
                self.message = "\(app.name) 的指定输入法未启用，请在系统键盘设置中添加。"
            case .select(let target):
                guard self.currentSourceID != target else {
                    self.message = "\(app.name) · 已是\(self.name(for: target))"; return
                }
                guard InputSources.select(target) else {
                    self.message = "\(app.name) 切换未成功，请检查输入法是否可用。"; return
                }
                do { try await Task.sleep(for: .milliseconds(220)) } catch { return }
                guard !Task.isCancelled, NSWorkspace.shared.frontmostApplication?.processIdentifier == processID else { return }
                self.refreshSources()
                // A bounded second attempt handles delayed input-method activation.
                // Never steal focus, simulate keys, or continually enforce a rule.
                if self.currentSourceID != target {
                    _ = InputSources.select(target)
                    do { try await Task.sleep(for: .milliseconds(220)) } catch { return }
                    guard !Task.isCancelled, NSWorkspace.shared.frontmostApplication?.processIdentifier == processID else { return }
                    self.refreshSources()
                }
                if self.currentSourceID == target {
                    self.message = "\(app.name) → \(self.name(for: target))"
                } else {
                    self.message = "\(app.name) 未接受切换，可手动选一次输入法后重试。"
                }
            }
        }
    }

    func refreshLoginStatus() {
        loginEnabled = SMAppService.mainApp.status == .enabled
        loginRequiresApproval = SMAppService.mainApp.status == .requiresApproval
    }

    func setLoginEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            refreshLoginStatus()
            if loginRequiresApproval { SMAppService.openSystemSettingsLoginItems() }
        } catch {
            refreshLoginStatus()
            errorMessage = "开机启动设置未完成：\(error.localizedDescription)。建议先将应用放入“应用程序”文件夹。"
        }
    }

    func exportConfiguration() {
        let panel = NSSavePanel()
        panel.title = "导出应用规则"
        panel.nameFieldStringValue = "水獭助手-规则.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try ConfigurationStore.encode(configuration).write(to: url, options: .atomic) }
        catch { errorMessage = "导出失败：\(error.localizedDescription)" }
    }

    func importConfiguration() {
        let panel = NSOpenPanel()
        panel.title = "导入应用规则"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            var imported = try ConfigurationStore.decode(Data(contentsOf: url))
            let alert = NSAlert()
            alert.messageText = "导入 \(imported.rules.count) 条应用规则？"
            alert.informativeText = "将替换当前规则，原配置会先保存备份。自动切换的开关保持当前状态。"
            alert.addButton(withTitle: "导入")
            alert.addButton(withTitle: "取消")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            _ = try store.backup()
            imported.enabled = configuration.enabled
            guard !persistenceBlocked else { errorMessage = "请先备份并重建原配置。"; return }
            try store.save(imported)
            pendingSwitch?.cancel()
            configuration = imported
            errorMessage = nil
            message = "已导入 \(imported.rules.count) 条规则，旧配置已备份。"
        } catch { errorMessage = "导入失败，当前规则未更改：\(error.localizedDescription)" }
    }

    func recoverConfiguration() {
        do {
            let backup = try store.backup()
            var fresh = Configuration()
            fresh.enabled = false
            try store.save(fresh)
            configuration = fresh
            persistenceBlocked = false
            errorMessage = nil
            message = "已建立空配置，原文件备份为 \(backup?.lastPathComponent ?? "备份文件")。"
        } catch { errorMessage = "重建失败，原文件保留：\(error.localizedDescription)" }
    }

    var needsRecovery: Bool { persistenceBlocked }
    func revealConfiguration() {
        if FileManager.default.fileExists(atPath: store.url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([store.url])
        } else { message = "添加第一条规则或更改设置后，会自动创建本地配置文件。" }
    }
}
