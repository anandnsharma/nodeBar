import Foundation

enum Constants {
    static let configDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".nodebar")
    static let configFilePath = configDirectory.appendingPathComponent("config.json")
    static let defaultMaxLogLines = 1000
    static let portDetectionInterval: TimeInterval = 5
    static let gracefulShutdownTimeout: TimeInterval = 5

    static let portPatterns: [String] = [
        #"(?:listening|running|started|ready|available)\s+(?:on|at)\s+(?:port\s+)?(\d{2,5})"#,
        #"(?:http|https)://(?:localhost|127\.0\.0\.1|0\.0\.0\.0):(\d{2,5})"#,
        #"port\s*[:=]\s*(\d{2,5})"#,
        #"localhost:(\d{2,5})"#,
    ]
}
