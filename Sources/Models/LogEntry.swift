import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let isError: Bool

    init(message: String, isError: Bool = false) {
        self.timestamp = Date()
        self.message = message
        self.isError = isError
    }
}
