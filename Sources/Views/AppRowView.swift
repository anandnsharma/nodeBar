import SwiftUI

struct AppRowView: View {
    let app: NodeApp
    let status: AppStatus
    let ports: [Int]
    let onStart: () -> Void
    let onStop: () -> Void
    let onOpenBrowser: () -> Void
    let onOpenPort: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Image(systemName: status.systemImage)
                .foregroundStyle(status.color)
                .font(.system(size: 10))
                .frame(width: 14)

            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                if status == .starting {
                    Text("Detecting port...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else if !ports.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(ports, id: \.self) { port in
                            Button {
                                onOpenPort(port)
                            } label: {
                                Text(":\(port)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                } else if status == .error {
                    Text("Error")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                } else {
                    Text(app.directoryPath.components(separatedBy: "/").suffix(2).joined(separator: "/"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 4) {
                if status == .running || status == .starting {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Stop")
                } else if status == .stopping {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Start")
                }

                if !ports.isEmpty {
                    Button(action: onOpenBrowser) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Open in browser")
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
