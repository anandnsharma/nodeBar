import Foundation

struct GlobalSettings: Codable, Equatable {
    var launchAtLogin: Bool = false
    var autoStartApps: Bool = true
    var maxLogLines: Int = Constants.defaultMaxLogLines
}

struct AppConfig: Codable {
    var version: Int = 1
    var globalSettings: GlobalSettings = GlobalSettings()
    var apps: [NodeApp] = []
}

final class ConfigurationService {
    private let fileManager = FileManager.default

    func load() -> AppConfig {
        guard fileManager.fileExists(atPath: Constants.configFilePath.path) else {
            return AppConfig()
        }
        do {
            let data = try Data(contentsOf: Constants.configFilePath)
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
            return AppConfig()
        }
    }

    func save(_ config: AppConfig) {
        do {
            try fileManager.createDirectory(
                at: Constants.configDirectory,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: Constants.configFilePath, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
