import SwiftUI

struct DownloadRowView: View {
    let task: DownloadTask
    let onCancel: () -> Void
    let onResume: () -> Void
    let onRemove: () -> Void
    let onRevealInFinder: () -> Void
    let onOpenFile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // タイトル
            Text(task.title)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.tail)

            // ダウンロード中
            if task.status == .downloading {
                // フェーズ表示
                HStack(spacing: 4) {
                    phaseIndicator
                    Spacer()
                    // キャンセルボタン
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.cancelHelp)
                }

                ProgressView(value: task.progress)
                    .tint(phaseColor)

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
                        Text(L10n.remaining(task.eta))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

            } else if task.status == .processing {
                // 処理中
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(L10n.converting)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Spacer()
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.cancelHelp)
                }

            } else if task.status == .completed {
                // 完了 — アクションボタン
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption2)
                    Text(L10n.completed)
                        .font(.caption2)
                        .foregroundStyle(.green)

                    Spacer()

                    if task.outputFilePath != nil {
                        Button {
                            onOpenFile()
                        } label: {
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(.plain)
                        .help(L10n.openFile)
                    }

                    Button {
                        onRevealInFinder()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.plain)
                    .help(L10n.revealInFinder)

                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.removeFromList)
                }

            } else if task.status == .waiting {
                HStack {
                    statusBadge
                    Spacer()
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.cancelHelp)
                }

            } else {
                // failed / cancelled
                HStack {
                    statusBadge
                    Spacer()
                    Button {
                        onResume()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                    .buttonStyle(.plain)
                    .help(L10n.resume)

                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.removeFromList)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // フェーズインジケータ
    @ViewBuilder
    private var phaseIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: phaseIcon)
                .font(.caption2)
                .foregroundStyle(phaseColor)
            Text(L10n.downloadingPhase(task.phase.displayName))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var phaseIcon: String {
        switch task.phase {
        case .video: return "film"
        case .audio: return "waveform"
        case .postProcess: return "gearshape"
        }
    }

    private var phaseColor: Color {
        switch task.phase {
        case .video: return .blue
        case .audio: return .purple
        case .postProcess: return .orange
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(task.status.displayName)
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
