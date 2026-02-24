import SwiftUI

struct EmptyStateView: View {
    let onAddApp: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No apps registered")
                .font(.headline)
            Text("Add a Node.js project to get started.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Add App") {
                onAddApp()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
