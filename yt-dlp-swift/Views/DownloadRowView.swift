import SwiftUI

struct DownloadRowView: View {
    let task: DownloadTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // タイトル
            Text(task.title)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.tail)

            // 進捗バー
            if task.status == .downloading {
                ProgressView(value: task.progress) {
                    HStack {
                        Text(String(format: "%.1f%%", task.progress * 100))
                            .font(.caption2)
                            .monospacedDigit()
                        Spacer()
                        if !task.speed.isEmpty {
                            Text(task.speed)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if !task.eta.isEmpty {
                            Text("残り \(task.eta)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.blue)
            } else if task.status == .processing {
                ProgressView()
                    .controlSize(.small)
                HStack {
                    Text("処理中...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                statusBadge
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(task.status.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if task.status == .failed, let error = task.error {
                Text("- \(error)")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .waiting: return .gray
        case .downloading: return .blue
        case .processing: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .paused: return .yellow
        }
    }
}
