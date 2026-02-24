import Foundation
import AppKit

@Observable
final class AppManager {
    var apps: [NodeApp] = []
    var statuses: [UUID: AppStatus] = [:]
    var detectedPorts: [UUID: Set<Int>] = [:]
    var logs: [UUID: [LogEntry]] = [:]
    var globalSettings = GlobalSettings()
    var selectedAppId: UUID?

    private let configService = ConfigurationService()
    private let processService = ProcessService()
    private let portDetectionService = PortDetectionService()

    init() {
        loadConfig()
    }

    // MARK: - Config

    func loadConfig() {
        let config = configService.load()
        apps = config.apps
        globalSettings = config.globalSettings
        for app in apps {
            statuses[app.id] = .stopped
            logs[app.id] = []
            detectedPorts[app.id] = []
        }
    }

    func saveConfig() {
        var config = AppConfig()
        config.apps = apps
        config.globalSettings = globalSettings
        configService.save(config)
    }

    // MARK: - App Management

    func addApp(_ app: NodeApp) {
        apps.append(app)
        statuses[app.id] = .stopped
        logs[app.id] = []
        detectedPorts[app.id] = []
        saveConfig()
    }

    func removeApp(id: UUID) {
        stopApp(id: id)
        apps.removeAll { $0.id == id }
        statuses.removeValue(forKey: id)
        logs.removeValue(forKey: id)
        detectedPorts.removeValue(forKey: id)
        if selectedAppId == id { selectedAppId = nil }
        saveConfig()
    }

    func updateApp(_ app: NodeApp) {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }
        let wasRunning = statuses[app.id] == .running
        if wasRunning { stopApp(id: app.id) }
        apps[index] = app
        saveConfig()
    }

    // MARK: - Process Control

    func startApp(id: UUID) {
        guard let app = apps.first(where: { $0.id == id }) else { return }
        guard statuses[id] == .stopped || statuses[id] == .error else { return }

        statuses[id] = .starting
        logs[id] = []
        detectedPorts[id] = []

        appendLog(appId: id, message: "Starting: \(app.startCommand)", isError: false)

        do {
            try processService.start(
                appId: id,
                command: app.startCommand,
                directory: app.directoryPath,
                environment: app.environmentVariables,
                onOutput: { [weak self] text, isError in
                    DispatchQueue.main.async {
                        self?.handleOutput(appId: id, text: text, isError: isError)
                    }
                },
                onExit: { [weak self] status in
                    DispatchQueue.main.async {
                        self?.handleExit(appId: id, status: status)
                    }
                }
            )

            // Start port polling after a short delay to let the process start
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self, let pid = self.processService.pid(for: id) else { return }
                self.portDetectionService.startPolling(appId: id, pid: pid) { [weak self] ports in
                    guard let self else { return }
                    let existing = self.detectedPorts[id] ?? []
                    self.detectedPorts[id] = existing.union(ports)
                    if self.statuses[id] == .starting && !ports.isEmpty {
                        self.statuses[id] = .running
                    }
                }
            }

            // Transition to running after a brief delay if not already
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.statuses[id] == .starting {
                    self?.statuses[id] = .running
                }
            }
        } catch {
            statuses[id] = .error
            appendLog(appId: id, message: "Failed to start: \(error.localizedDescription)", isError: true)
        }
    }

    func stopApp(id: UUID) {
        guard statuses[id] == .running || statuses[id] == .starting else { return }
        statuses[id] = .stopping
        appendLog(appId: id, message: "Stopping...", isError: false)
        portDetectionService.stopPolling(appId: id)
        processService.stop(appId: id)
    }

    func restartApp(id: UUID) {
        stopApp(id: id)
        // Wait for process to actually stop before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.startApp(id: id)
        }
    }

    func startAll() {
        for app in apps where statuses[app.id] == .stopped || statuses[app.id] == .error {
            startApp(id: app.id)
        }
    }

    func stopAll() {
        portDetectionService.stopAllPolling()
        processService.stopAll()
        for app in apps {
            if statuses[app.id] == .running || statuses[app.id] == .starting {
                statuses[app.id] = .stopping
            }
        }
        // Mark all as stopped after grace period
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            for app in self.apps {
                if self.statuses[app.id] == .stopping {
                    self.statuses[app.id] = .stopped
                    self.detectedPorts[app.id] = []
                }
            }
        }
    }

    func autoStartApps() {
        guard globalSettings.autoStartApps else { return }
        for app in apps where app.autoStart {
            startApp(id: app.id)
        }
    }

    // MARK: - Browser

    func openInBrowser(appId: UUID) {
        let ports = effectivePorts(for: appId)
        guard let port = ports.first else { return }
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }

    func openPort(_ port: Int) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Helpers

    func effectivePorts(for appId: UUID) -> [Int] {
        let app = apps.first { $0.id == appId }
        let specified = app?.specifiedPorts ?? []
        let detected = Array(detectedPorts[appId] ?? [])
        return specified.isEmpty ? detected.sorted() : specified.sorted()
    }

    var hasRunningApps: Bool {
        runningCount > 0
    }

    var runningCount: Int {
        statuses.values.filter { $0 == .running || $0 == .starting }.count
    }

    private func handleOutput(appId: UUID, text: String, isError: Bool) {
        appendLog(appId: appId, message: text, isError: isError)

        // Try to detect ports from output
        let ports = portDetectionService.detectPortsFromOutput(text)
        if !ports.isEmpty {
            let existing = detectedPorts[appId] ?? []
            detectedPorts[appId] = existing.union(ports)
            if statuses[appId] == .starting {
                statuses[appId] = .running
            }
        }
    }

    private func handleExit(appId: UUID, status: Int32) {
        portDetectionService.stopPolling(appId: appId)
        detectedPorts[appId] = []

        if statuses[appId] == .stopping {
            statuses[appId] = .stopped
            appendLog(appId: appId, message: "Stopped.", isError: false)
        } else {
            statuses[appId] = status == 0 ? .stopped : .error
            appendLog(
                appId: appId,
                message: "Process exited with code \(status).",
                isError: status != 0
            )
        }
    }

    private func appendLog(appId: UUID, message: String, isError: Bool) {
        let entry = LogEntry(message: message, isError: isError)
        if logs[appId] == nil { logs[appId] = [] }
        logs[appId]?.append(entry)
        // Trim to max log lines
        let max = globalSettings.maxLogLines
        if let count = logs[appId]?.count, count > max {
            logs[appId]?.removeFirst(count - max)
        }
    }
}
