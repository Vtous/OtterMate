import Foundation

struct AppRule: Codable, Equatable, Identifiable {
    var bundleID: String
    var appName: String
    var appPath: String
    var inputSourceID: String
    var enabled = true
    var id: String { bundleID }
}

struct Configuration: Codable, Equatable {
    var version = 1
    var enabled = true
    var defaultSourceID: String? = nil
    var rules: [AppRule] = []

    func validated() throws -> Configuration {
        guard version == 1 else { throw ConfigurationError.unsupportedVersion(version) }
        var identifiers = Set<String>()
        for rule in rules {
            guard !rule.bundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !rule.inputSourceID.isEmpty,
                  identifiers.insert(rule.bundleID).inserted else {
                throw ConfigurationError.invalidRules
            }
        }
        return self
    }
}

enum ConfigurationError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidRules
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version): return "配置版本 \(version) 暂不支持，请使用较新版本的水獭助手。"
        case .invalidRules: return "配置包含重复、空白或不完整的应用规则。"
        }
    }
}

enum RuleDecision: Equatable {
    case paused
    case unchanged
    case missingSource(String)
    case select(String)
}

enum RuleResolver {
    static func decide(configuration: Configuration, appID: String, ownAppID: String,
                       available: Set<String>) -> RuleDecision {
        guard configuration.enabled else { return .paused }
        guard !appID.isEmpty, appID != ownAppID,
              appID != "com.apple.loginwindow", appID != "com.apple.SecurityAgent" else {
            return .unchanged
        }
        let target: String?
        if let rule = configuration.rules.first(where: { $0.bundleID == appID }) {
            // A disabled rule is an explicit exemption from the global default.
            guard rule.enabled else { return .unchanged }
            target = rule.inputSourceID
        } else {
            target = configuration.defaultSourceID
        }
        guard let target else { return .unchanged }
        guard available.contains(target) else { return .missingSource(target) }
        return .select(target)
    }
}

struct ConfigurationStore {
    let url: URL

    static var standard: ConfigurationStore {
        let override = ProcessInfo.processInfo.environment["APPINPUT_CONFIG_PATH"]
            ?? (Bundle.main.object(forInfoDictionaryKey: "AppInputConfigurationPath") as? String)
        let url = override.map { URL(fileURLWithPath: $0) } ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppInputSwitcher", isDirectory: true)
            .appendingPathComponent("rules.json")
        return ConfigurationStore(url: url)
    }

    func load() throws -> Configuration {
        guard FileManager.default.fileExists(atPath: url.path) else { return Configuration() }
        return try Self.decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> Configuration {
        try JSONDecoder().decode(Configuration.self, from: data).validated()
    }

    static func encode(_ configuration: Configuration) throws -> Data {
        _ = try configuration.validated()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(configuration)
    }

    func save(_ configuration: Configuration) throws {
        let data = try Self.encode(configuration)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    func backup() throws -> URL? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let destination = url.deletingLastPathComponent()
            .appendingPathComponent("rules-backup-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }
}
