import Foundation

@main
struct CoreTests {
    static var checks = 0
    static func expect(_ condition: Bool, _ description: String) {
        checks += 1
        guard condition else { fatalError("FAIL: \(description)") }
    }
    static func expectThrows(_ description: String, _ work: () throws -> Void) {
        checks += 1
        do { try work(); fatalError("FAIL: \(description)") } catch {}
    }

    static func main() throws {
        let appID = "test.chat"
        let ownID = "test.switcher"
        let doubao = "test.input.doubao"
        let abc = "com.apple.keylayout.ABC"
        let available: Set<String> = [doubao, abc]
        var config = Configuration()
        config.rules = [AppRule(bundleID: appID, appName: "Chat", appPath: "/Applications/Chat.app", inputSourceID: doubao)]
        func resolve(_ id: String, _ config: Configuration) -> RuleDecision {
            RuleResolver.decide(configuration: config, appID: id, ownAppID: ownID, available: available)
        }
        expect(resolve(appID, config) == .select(doubao), "explicit app rule wins")
        expect(resolve("test.unknown", config) == .unchanged, "unknown app stays unchanged by default")
        config.defaultSourceID = abc
        expect(resolve(appID, config) == .select(doubao), "app rule overrides fallback")
        expect(resolve("test.unknown", config) == .select(abc), "unknown app uses configured fallback")
        config.rules[0].enabled = false
        expect(resolve(appID, config) == .unchanged, "disabled rule exempts app from fallback")
        config.rules[0].enabled = true
        expect(resolve(ownID, config) == .unchanged, "settings app cannot trigger switching")
        expect(resolve("", config) == .unchanged, "empty bundle identity cannot trigger fallback")
        expect(resolve("com.apple.loginwindow", config) == .unchanged, "login window excluded")
        expect(resolve("com.apple.SecurityAgent", config) == .unchanged, "authentication agent excluded")
        config.rules[0].inputSourceID = "missing.input"
        expect(resolve(appID, config) == .missingSource("missing.input"), "missing rule never silently falls back")
        config.enabled = false
        expect(resolve(appID, config) == .paused, "pause takes precedence over missing source")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("app-input-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appendingPathComponent("nested/rules.json"))
        expect(tryLoad(store) == Configuration(), "first launch returns empty configuration")
        config.rules[0].inputSourceID = doubao
        try store.save(config)
        expect(tryLoad(store) == config, "all rules and settings survive disk roundtrip")
        let permissions = try FileManager.default.attributesOfItem(atPath: store.url.path)[.posixPermissions] as? NSNumber
        expect(permissions?.intValue == 0o600, "configuration file is private to user")
        let backup = try store.backup()!
        let previousData = try Data(contentsOf: backup)
        config.rules = []
        try store.save(config)
        expect(try Data(contentsOf: backup) == previousData, "saving new rules does not alter backup")
        expect(tryLoad(store)?.rules.isEmpty == true, "deleting last rule persists")
        var duplicate = Configuration()
        let rule = AppRule(bundleID: appID, appName: "Chat", appPath: "", inputSourceID: doubao)
        duplicate.rules = [rule, rule]
        let beforeRejectedSave = try Data(contentsOf: store.url)
        expectThrows("duplicate IDs rejected before disk write") { try store.save(duplicate) }
        expect(try Data(contentsOf: store.url) == beforeRejectedSave, "failed validation preserves original file")
        var future = Configuration(); future.version = 99
        expectThrows("future schema rejected") { _ = try future.validated() }
        let corrupt = Data("not json".utf8)
        try corrupt.write(to: store.url)
        expectThrows("corrupt file reported rather than silently reset") { _ = try store.load() }
        expect(try Data(contentsOf: store.url) == corrupt, "loading corrupt file leaves it untouched")
        expectThrows("malformed import rejected") { _ = try ConfigurationStore.decode(Data("{}".utf8)) }
        print("PASS: \(checks) checks (rule priority, pause, unavailable sources, persistence, backups, corrupt configuration)")
    }

    static func tryLoad(_ store: ConfigurationStore) -> Configuration? { try? store.load() }
}
