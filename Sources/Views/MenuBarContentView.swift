import SwiftUI

struct MenuBarContentView: View {
    @Bindable var manager: AppManager
    @State private var showingAddApp = false
    @State private var showingSettings = false
    @State private var showingQuitConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("nodeBar")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Button {
                    showingAddApp = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Add app")

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Settings")

                Button {
                    handleQuit()
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Quit")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Content
            if showingAddApp {
                AddAppView(manager: manager, isPresented: $showingAddApp)
            } else if showingSettings {
                SettingsView(manager: manager, isPresented: $showingSettings)
            } else if let selectedId = manager.selectedAppId {
                AppDetailView(manager: manager, appId: selectedId)
            } else if manager.apps.isEmpty {
                EmptyStateView {
                    showingAddApp = true
                }
            } else {
                AppListView(manager: manager)
            }

            // Footer (shown only when apps exist and in list view)
            if !manager.apps.isEmpty && manager.selectedAppId == nil && !showingAddApp && !showingSettings {
                Divider()
                HStack {
                    if manager.hasRunningApps {
                        Button("Stop All") {
                            manager.stopAll()
                        }
                        .controlSize(.small)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(manager.apps.count) app\(manager.apps.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .alert("Quit nodeBar?", isPresented: $showingQuitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Stop All & Quit", role: .destructive) {
                manager.stopAll()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NSApp.terminate(nil)
                }
            }
        } message: {
            Text("Some apps are still running. They will be stopped before quitting.")
        }
    }

    private func handleQuit() {
        if manager.hasRunningApps {
            showingQuitConfirmation = true
        } else {
            NSApp.terminate(nil)
        }
    }
}
