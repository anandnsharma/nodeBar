import Foundation

struct NodeApp: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var directoryPath: String
    var startCommand: String
    var specifiedPorts: [Int]
    var autoStart: Bool
    var environmentVariables: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        directoryPath: String,
        startCommand: String = "npm start",
        specifiedPorts: [Int] = [],
        autoStart: Bool = false,
        environmentVariables: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.directoryPath = directoryPath
        self.startCommand = startCommand
        self.specifiedPorts = specifiedPorts
        self.autoStart = autoStart
        self.environmentVariables = environmentVariables
    }
}
