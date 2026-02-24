import XCTest
@testable import nodeBar

final class NodeBarTests: XCTestCase {

    func testConfigRoundTrip() throws {
        var config = AppConfig()
        config.apps = [
            NodeApp(name: "Test", directoryPath: "/tmp/test", startCommand: "npm start")
        ]
        config.globalSettings.maxLogLines = 500

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(config)
        let decoded = try decoder.decode(AppConfig.self, from: data)

        XCTAssertEqual(decoded.apps.count, 1)
        XCTAssertEqual(decoded.apps[0].name, "Test")
        XCTAssertEqual(decoded.globalSettings.maxLogLines, 500)
    }

    func testPortDetectionFromOutput() {
        let service = PortDetectionService()

        let tests: [(String, Set<Int>)] = [
            ("Server listening on port 3000", [3000]),
            ("http://localhost:8080", [8080]),
            ("App running at http://0.0.0.0:4000", [4000]),
            ("ready on http://localhost:3001", [3001]),
            ("no port here", []),
        ]

        for (input, expected) in tests {
            let detected = service.detectPortsFromOutput(input)
            XCTAssertEqual(detected, expected, "Input: \(input)")
        }
    }
}
