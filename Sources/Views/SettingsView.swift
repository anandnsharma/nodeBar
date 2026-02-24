import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var manager: AppManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Settings")
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

            Toggle("Launch at login", isOn: Binding(
                get: { manager.globalSettings.launchAtLogin },
                set: { newValue in
                    manager.globalSettings.launchAtLogin = newValue
                    updateLaunchAtLogin(newValue)
                    manager.saveConfig()
                }
            ))
            .controlSize(.small)

            Toggle("Auto-start apps on launch", isOn: Binding(
                get: { manager.globalSettings.autoStartApps },
                set: { newValue in
                    manager.globalSettings.autoStartApps = newValue
                    manager.saveConfig()
                }
            ))
            .controlSize(.small)

            HStack {
                Text("Max log lines:")
                    .font(.caption)
                TextField("", value: Binding(
                    get: { manager.globalSettings.maxLogLines },
                    set: { newValue in
                        manager.globalSettings.maxLogLines = newValue
                        manager.saveConfig()
                    }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .frame(width: 80)
            }

            Divider()

            Text("Config: \(Constants.configFilePath.path)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(12)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
