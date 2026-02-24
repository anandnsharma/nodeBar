import Foundation

final class ProcessService {
    struct RunningProcess {
        let process: Process
        let stdoutPipe: Pipe
        let stderrPipe: Pipe
    }

    private var processes: [UUID: RunningProcess] = [:]

    func start(
        appId: UUID,
        command: String,
        directory: String,
        environment: [String: String],
        onOutput: @escaping (String, Bool) -> Void,
        onExit: @escaping (Int32) -> Void
    ) throws {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Merge user environment with custom variables
        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            env[key] = value
        }
        process.environment = env

        // Create a new process group so we can kill the entire tree
        process.qualityOfService = .userInitiated

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            onOutput(text, false)
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            onOutput(text, true)
        }

        process.terminationHandler = { proc in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            onExit(proc.terminationStatus)
        }

        try process.run()
        processes[appId] = RunningProcess(
            process: process,
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe
        )
    }

    func stop(appId: UUID) {
        guard let running = processes[appId] else { return }
        let process = running.process
        guard process.isRunning else {
            processes.removeValue(forKey: appId)
            return
        }

        let pid = process.processIdentifier
        // Kill entire process group (npm spawns child node processes)
        kill(-pid, SIGTERM)

        // Schedule force kill after timeout
        DispatchQueue.global().asyncAfter(
            deadline: .now() + Constants.gracefulShutdownTimeout
        ) { [weak self] in
            if process.isRunning {
                kill(-pid, SIGKILL)
            }
            self?.processes.removeValue(forKey: appId)
        }
    }

    func stopAll() {
        for appId in processes.keys {
            stop(appId: appId)
        }
    }

    func isRunning(appId: UUID) -> Bool {
        processes[appId]?.process.isRunning ?? false
    }

    func pid(for appId: UUID) -> Int32? {
        guard let process = processes[appId]?.process, process.isRunning else { return nil }
        return process.processIdentifier
    }
}
