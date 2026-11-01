import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    private var filteredRules: [AppRule] {
        model.configuration.rules.filter {
            model.searchQuery.isEmpty || $0.appName.localizedCaseInsensitiveContains(model.searchQuery) ||
                $0.bundleID.localizedCaseInsensitiveContains(model.searchQuery)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            if let error = model.errorMessage {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(error).font(.callout).textSelection(.enabled)
                    Spacer(minLength: 0)
                    if model.needsRecovery {
                        Button("备份并重建") { model.recoverConfiguration() }
                    }
                }.padding(12).background(.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            }
            overview
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("应用规则").font(.headline)
                    Text("\(model.configuration.rules.count)").font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary).padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                    Spacer()
                    TextField("搜索应用", text: $model.searchQuery).textFieldStyle(.roundedBorder).frame(width: 160)
                    Button { model.chooseApplications() } label: { Label("添加应用", systemImage: "plus") }
                        .accessibilityIdentifier("add-applications")
                }.padding(16)
                Divider()
                if model.configuration.rules.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "app.badge.checkmark").font(.system(size: 34)).foregroundStyle(.blue.opacity(0.8))
                        Text("让每个应用，用上你习惯的输入法").font(.headline)
                        Text("例如：微信用豆包，终端用 ABC。进入应用时自动切换一次。")
                            .foregroundStyle(.secondary).font(.callout)
                        Button("添加第一个应用") { model.chooseApplications() }.buttonStyle(.borderedProminent)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(24)
                } else if filteredRules.isEmpty {
                    Text("没有匹配的应用").foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredRules) { rule in
                                ruleRow(rule)
                                if rule.id != filteredRules.last?.id { Divider().padding(.leading, 62) }
                            }
                        }
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary))
            .frame(minHeight: 200)

            VStack(spacing: 12) {
                HStack {
                    Label("其他应用", systemImage: "square.grid.2x2").font(.callout)
                    Spacer()
                    Picker("其他应用默认输入法", selection: Binding(
                        get: { model.configuration.defaultSourceID ?? "" }, set: { model.setDefault($0) })) {
                        Text("保持原输入法").tag("")
                        sourceOptions(selected: model.configuration.defaultSourceID)
                    }.labelsHidden().frame(width: 235)
                }
                Divider()
                HStack {
                    Toggle("登录后自动启动", isOn: Binding(
                        get: { model.loginEnabled || model.loginRequiresApproval }, set: { model.setLoginEnabled($0) }))
                        .toggleStyle(.checkbox).font(.callout)
                    if model.loginRequiresApproval {
                        Text("等待系统批准").font(.caption).foregroundStyle(.orange)
                    }
                    Spacer()
                    Menu("规则备份") {
                        Button("导出规则…") { model.exportConfiguration() }
                        Button("导入规则…") { model.importConfiguration() }
                        Divider()
                        Button("查看配置文件") { model.revealConfiguration() }
                    }.menuStyle(.borderlessButton).fixedSize()
                    Button { model.refreshSources(); model.refreshLoginStatus() } label: {
                        Image(systemName: "arrow.clockwise")
                    }.buttonStyle(.borderless).help("刷新输入法和开机启动状态")
                }
            }.padding(16)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary))

            HStack(spacing: 6) {
                Image(systemName: "lock.shield").foregroundStyle(.secondary)
                Text("本地保存 · 无联网功能 · 无需辅助功能或输入监控权限")
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
            }.font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 780, minHeight: 650)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 13) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 62, height: 62)
                .accessibilityLabel("OtterMate 水獭抱键盘图标")
            VStack(alignment: .leading, spacing: 4) {
                Text("水獭助手").font(.system(size: 24, weight: .bold))
                Text("OtterMate · 切到哪个应用，就用哪个输入法。").font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(model.configuration.enabled ? "自动切换已开启" : "已暂停", isOn: Binding(
                get: { model.configuration.enabled }, set: { model.setEnabled($0) }))
                .toggleStyle(.switch).fixedSize()
                .accessibilityIdentifier("automatic-switching")
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(model.configuration.enabled ? .green : .gray).frame(width: 7, height: 7)
                Text(model.message).font(.callout).lineLimit(2)
                Spacer()
                Text(model.currentSourceName).font(.caption.weight(.medium))
                    .padding(.horizontal, 9).padding(.vertical, 5).background(.blue.opacity(0.09), in: Capsule())
            }
            HStack {
                Text("最近使用：\(model.activeApp?.name ?? "等待切换到其他应用")")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
                if let app = model.activeApp,
                   !model.configuration.rules.contains(where: { $0.bundleID == app.bundleID }) {
                    Button("为“\(app.name)”添加规则") { model.addActiveApp() }
                        .font(.caption).buttonStyle(.link)
                        .accessibilityIdentifier("add-active-application")
                }
            }
        }.padding(14)
            .background(.blue.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }

    private func ruleRow(_ rule: AppRule) -> some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: rule.appPath)).resizable().frame(width: 32, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.appName).font(.body.weight(.medium)).lineLimit(1)
                Text(rule.enabled ? "进入应用时切换" : "保持原输入法，不应用默认规则")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Picker("\(rule.appName)的输入法", selection: Binding(
                get: { rule.inputSourceID }, set: { model.setRuleSource(rule.bundleID, $0) })) {
                    sourceOptions(selected: rule.inputSourceID)
                }.labelsHidden().frame(width: 200).disabled(!rule.enabled)
            Toggle("启用\(rule.appName)规则", isOn: Binding(
                get: { rule.enabled }, set: { model.setRuleEnabled(rule.bundleID, $0) }))
                .labelsHidden().toggleStyle(.switch).controlSize(.small)
            Button { model.removeRule(rule.bundleID) } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.borderless).foregroundStyle(.secondary)
                .help("移除\(rule.appName)规则").accessibilityLabel("移除\(rule.appName)规则")
        }.padding(.horizontal, 16).padding(.vertical, 13)
    }

    @ViewBuilder
    private func sourceOptions(selected: String?) -> some View {
        if let selected, !model.sources.contains(where: { $0.id == selected }) {
            Text("输入法未启用（请重新选择）").tag(selected)
        }
        ForEach(model.sources) { source in Text(source.name).tag(source.id) }
    }
}
