import SwiftUI

struct AppDetailView: View {
    @Bindable var manager: AppManager
    let appId: UUID

    @State private var isEditing = false
    @State private var editName = ""
    @State private var editCommand = ""
    @State private var editAutoStart = false

    private var app: NodeApp? {
        manager.apps.first { $0.id == appId }
    }

    private var status: AppStatus {
        manager.statuses[appId] ?? .stopped
    }

    private var logEntries: [LogEntry] {
        manager.logs[appId] ?? []
    }

    var body: some View {
        if let app {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Button {
                        manager.selectedAppId = nil
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: status.systemImage)
                        .foregroundStyle(status.color)
                        .font(.system(size: 10))

                    Text(app.name)
                        .font(.headline)

                    Spacer()

                    Button {
                        isEditing.toggle()
                        if isEditing {
                            editName = app.name
                            editCommand = app.startCommand
                            editAutoStart = app.autoStart
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Edit")
                }

                if isEditing {
                    editSection(app: app)
                } else {
                    infoSection(app: app)
                }

                // Logs
                if !logEntries.isEmpty {
                    Text("Logs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LogView(entries: logEntries)
                        .frame(height: 200)
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func infoSection(app: NodeApp) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent("Directory") {
                Text(app.directoryPath)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.caption)

            LabeledContent("Command") {
                Text(app.startCommand)
                    .font(.system(size: 11, design: .monospaced))
            }
            .font(.caption)

            let ports = manager.effectivePorts(for: appId)
            if !ports.isEmpty {
                LabeledContent("Ports") {
                    Text(ports.map(String.init).joined(separator: ", "))
                        .font(.system(size: 11, design: .monospaced))
                }
                .font(.caption)
            }

            LabeledContent("Auto-start") {
                Text(app.autoStart ? "Yes" : "No")
                    .font(.system(size: 11))
            }
            .font(.caption)
        }

        // Action buttons
        HStack(spacing: 8) {
            if status == .running || status == .starting {
                Button("Stop") { manager.stopApp(id: appId) }
                    .controlSize(.small)
                Button("Restart") { manager.restartApp(id: appId) }
                    .controlSize(.small)
            } else {
                Button("Start") { manager.startApp(id: appId) }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
            }

            let ports = manager.effectivePorts(for: appId)
            if !ports.isEmpty {
                Button("Open in Browser") { manager.openInBrowser(appId: appId) }
                    .controlSize(.small)
            }

            Spacer()

            Button(role: .destructive) {
                manager.removeApp(id: appId)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .help("Remove app")
        }
    }

    @ViewBuilder
    private func editSection(app: NodeApp) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $editName)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            TextField("Start Command", text: $editCommand)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            Toggle("Auto-start", isOn: $editAutoStart)
                .controlSize(.small)

            HStack {
                Button("Save") {
                    var updated = app
                    updated.name = editName
                    updated.startCommand = editCommand
                    updated.autoStart = editAutoStart
                    manager.updateApp(updated)
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Cancel") {
                    isEditing = false
                }
                .controlSize(.small)
            }
        }
    }
}
