import SwiftUI

enum AppStatus: String, Codable {
    case stopped
    case starting
    case running
    case stopping
    case error

    var color: Color {
        switch self {
        case .stopped: .gray
        case .starting: .yellow
        case .running: .green
        case .stopping: .orange
        case .error: .red
        }
    }

    var label: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .stopped: "circle"
        case .starting: "circle.dotted"
        case .running: "circle.fill"
        case .stopping: "circle.dotted"
        case .error: "exclamationmark.circle.fill"
        }
    }
}
