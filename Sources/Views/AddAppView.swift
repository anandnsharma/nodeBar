import SwiftUI
import AppKit

struct AddAppView: View {
    @Bindable var manager: AppManager
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var directoryPath = ""
    @State private var startCommand = "npm start"
    @State private var autoStart = false
    @State private var portsText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add App")
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }

            // Directory picker
            HStack {
                TextField("Project directory", text: $directoryPath)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                Button("Browse...") {
                    pickFolder()
                }
                .controlSize(.small)
            }

            TextField("App name", text: $name)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            TextField("Start command", text: $startCommand)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            TextField("Ports (comma-separated, optional)", text: $portsText)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            Toggle("Auto-start with nodeBar", isOn: $autoStart)
                .controlSize(.small)

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .controlSize(.small)

                Button("Add") {
                    addApp()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(directoryPath.isEmpty || startCommand.isEmpty)
            }
        }
        .padding(12)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a Node.js project directory"

        NSApp.setActivationPolicy(.regular)
        if panel.runModal() == .OK, let url = panel.url {
            directoryPath = url.path
            if name.isEmpty {
                name = url.lastPathComponent
            }
        }
        NSApp.setActivationPolicy(.accessory)
    }

    private func addApp() {
        let ports = portsText
            .components(separatedBy: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        let effectiveName = name.isEmpty
            ? URL(fileURLWithPath: directoryPath).lastPathComponent
            : name

        let app = NodeApp(
            name: effectiveName,
            directoryPath: directoryPath,
            startCommand: startCommand,
            specifiedPorts: ports,
            autoStart: autoStart
        )
        manager.addApp(app)
        isPresented = false
    }
}
