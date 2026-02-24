import SwiftUI

struct AppListView: View {
    @Bindable var manager: AppManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.apps) { app in
                    let status = manager.statuses[app.id] ?? .stopped
                    let ports = manager.effectivePorts(for: app.id)

                    AppRowView(
                        app: app,
                        status: status,
                        ports: ports,
                        onStart: { manager.startApp(id: app.id) },
                        onStop: { manager.stopApp(id: app.id) },
                        onOpenBrowser: { manager.openInBrowser(appId: app.id) },
                        onOpenPort: { port in manager.openPort(port) }
                    )
                    .background(
                        manager.selectedAppId == app.id
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.selectedAppId = manager.selectedAppId == app.id ? nil : app.id
                        }
                    }
                    .contextMenu {
                        contextMenuItems(app: app, status: status)
                    }

                    if app.id != manager.apps.last?.id {
                        Divider()
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contextMenuItems(app: NodeApp, status: AppStatus) -> some View {
        if status == .running || status == .starting {
            Button("Stop") { manager.stopApp(id: app.id) }
            Button("Restart") { manager.restartApp(id: app.id) }
        } else {
            Button("Start") { manager.startApp(id: app.id) }
        }

        let ports = manager.effectivePorts(for: app.id)
        if !ports.isEmpty {
            Button("Open in Browser") { manager.openInBrowser(appId: app.id) }
        }

        Divider()

        Button("Show Details") {
            manager.selectedAppId = app.id
        }

        Divider()

        Button("Remove", role: .destructive) {
            manager.removeApp(id: app.id)
        }
    }
}
