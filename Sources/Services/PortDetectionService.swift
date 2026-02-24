import Foundation

final class PortDetectionService {
    private var pollingTimers: [UUID: Timer] = [:]
    private let portRegexes: [NSRegularExpression]

    init() {
        portRegexes = Constants.portPatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        }
    }

    /// Parse stdout/stderr text for port numbers
    func detectPortsFromOutput(_ text: String) -> Set<Int> {
        var ports = Set<Int>()
        for regex in portRegexes {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                if match.numberOfRanges > 1,
                   let portRange = Range(match.range(at: 1), in: text),
                   let port = Int(text[portRange]),
                   (1...65535).contains(port) {
                    ports.insert(port)
                }
            }
        }
        return ports
    }

    /// Start polling lsof for ports belonging to a process
    func startPolling(appId: UUID, pid: Int32, onPorts: @escaping (Set<Int>) -> Void) {
        stopPolling(appId: appId)

        let timer = Timer.scheduledTimer(
            withTimeInterval: Constants.portDetectionInterval,
            repeats: true
        ) { [weak self] _ in
            self?.queryPorts(pid: pid, completion: onPorts)
        }
        pollingTimers[appId] = timer
        // Run immediately once
        queryPorts(pid: pid, completion: onPorts)
    }

    func stopPolling(appId: UUID) {
        pollingTimers[appId]?.invalidate()
        pollingTimers.removeValue(forKey: appId)
    }

    func stopAllPolling() {
        for (appId, _) in pollingTimers {
            stopPolling(appId: appId)
        }
    }

    private func queryPorts(pid: Int32, completion: @escaping (Set<Int>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-a", "-p", "\(pid)"]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                return
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return }

            var ports = Set<Int>()
            // Also check child processes by looking at the process group
            for line in output.components(separatedBy: "\n") {
                // lsof output has port in the NAME column, e.g. *:3000 (LISTEN)
                let portRegex = try? NSRegularExpression(pattern: #":(\d+)\s"#)
                let range = NSRange(line.startIndex..., in: line)
                if let match = portRegex?.firstMatch(in: line, range: range),
                   match.numberOfRanges > 1,
                   let portRange = Range(match.range(at: 1), in: line),
                   let port = Int(line[portRange]) {
                    ports.insert(port)
                }
            }

            if !ports.isEmpty {
                DispatchQueue.main.async {
                    completion(ports)
                }
            }
        }
    }
}
