import SwiftUI

struct LogView: View {
    let entries: [LogEntry]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 6) {
                            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.tertiary)
                            Text(entry.message)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(entry.isError ? .red : .primary)
                                .textSelection(.enabled)
                        }
                        .id(entry.id)
                    }
                }
                .padding(8)
            }
            .background(.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onChange(of: entries.count) {
                if let last = entries.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}
