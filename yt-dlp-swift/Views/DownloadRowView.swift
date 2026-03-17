import SwiftUI

struct DownloadRowView: View {
    let task: DownloadTask
    let onCancel: () -> Void
    let onStopRecording: () -> Void
    let onResume: () -> Void
    let onRemove: () -> Void
    let onRevealInFinder: () -> Void
    let onOpenFile: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // サムネイル
            ZStack(alignment: .topLeading) {
                AsyncImage(url: thumbnailImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure:
                        thumbnailPlaceholder
                    case .empty:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
                .frame(width: 64, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // ライブ録画バッジ
                if task.isLiveRecording && (task.status == .recording || task.status == .downloading) {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(.white)
                            .frame(width: 4, height: 4)
                        Text("REC")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(.red, in: RoundedRectangle(cornerRadius: 2))
                    .padding(2)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
            // タイトル
            Text(task.title)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.tail)

            // 投稿者
            if let uploader = task.uploader {
                Text(uploader)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // 録画中
            if task.status == .recording {
                HStack(spacing: 4) {
                    recordingIndicator
                    Spacer()
                    // 録画停止ボタン
                    Button {
                        onStopRecording()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.stopRecording)

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

                // 経過時間とサイズ
                HStack {
                    if !task.recordingElapsed.isEmpty {
                        Text(L10n.recordingElapsed(task.recordingElapsed))
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    if !task.speed.isEmpty {
                        Text(task.speed)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !task.totalSize.isEmpty {
                        Text(task.totalSize)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

            // ダウンロード中
            } else if task.status == .downloading {
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
        }
        .padding(.vertical, 4)
    }

    private var thumbnailImageURL: URL? {
        guard let urlString = task.thumbnailURL else { return nil }
        return URL(string: urlString)
    }

    @ViewBuilder
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
            .frame(width: 64, height: 36)
            .overlay {
                Image(systemName: task.isLiveRecording ? "record.circle" : "play.rectangle")
                    .font(.system(size: 14))
                    .foregroundStyle(task.isLiveRecording ? Color.red.opacity(0.5) : Color.secondary)
            }
    }

    // 録画中インジケータ
    @ViewBuilder
    private var recordingIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            Text(L10n.statusRecording)
                .font(.caption2)
                .foregroundStyle(.red)
        }
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
        case .liveRecording: return "record.circle"
        }
    }

    private var phaseColor: Color {
        switch task.phase {
        case .video: return .blue
        case .audio: return .purple
        case .postProcess: return .orange
        case .liveRecording: return .red
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
        case .recording: return .red
        case .processing: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .paused: return .yellow
        }
    }
}
