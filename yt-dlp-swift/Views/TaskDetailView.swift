import SwiftUI

struct TaskDetailView: View {
    let task: DownloadTask
    @Environment(DownloadViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // サムネイル
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                    case .failure:
                        thumbnailPlaceholder
                    case .empty:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 16)

                // タイトル
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textSelection(.enabled)
                    .padding(.bottom, 4)

                // 投稿者
                if let uploader = task.uploader {
                    Text(uploader)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                }

                // ステータスバッジ
                statusSection
                    .padding(.bottom, 16)

                Divider()
                    .padding(.bottom, 16)

                // メタデータ
                metadataSection
                    .padding(.bottom, 16)

                // 概要
                if let description = task.videoDescription, !description.isEmpty {
                    Divider()
                        .padding(.bottom, 16)

                    Text(L10n.metadataDescription)
                        .font(.headline)
                        .padding(.bottom, 8)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - ステータス

    @ViewBuilder
    private var statusSection: some View {
        HStack(spacing: 12) {
            // ステータスバッジ
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(task.status.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
            }

            Spacer()

            // アクションボタン
            if task.status == .completed {
                if task.outputFilePath != nil {
                    Button {
                        viewModel.openFile(task)
                    } label: {
                        Label(L10n.openFile, systemImage: "play.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button {
                    viewModel.revealInFinder(task)
                } label: {
                    Label(L10n.revealInFinder, systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if task.status == .recording {
                Button {
                    viewModel.stopRecording(task)
                } label: {
                    Label(L10n.stopRecording, systemImage: "stop.circle.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            } else if task.status == .downloading || task.status == .processing {
                // 進捗表示
                if task.status == .downloading {
                    Text(String(format: "%.1f%%", task.progress * 100))
                        .font(.callout)
                        .monospacedDigit()
                }
            } else if task.status == .failed || task.status == .cancelled {
                Button {
                    viewModel.resumeTask(task)
                } label: {
                    Label(L10n.resume, systemImage: "arrow.clockwise.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }

        // 進捗バー
        if task.status == .downloading {
            ProgressView(value: task.progress)
                .padding(.top, 8)

            HStack {
                if !task.speed.isEmpty {
                    Text(task.speed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !task.eta.isEmpty {
                    Text(L10n.remaining(task.eta))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // 録画中の経過時間
        if task.status == .recording {
            HStack {
                if !task.recordingElapsed.isEmpty {
                    Text(L10n.recordingElapsed(task.recordingElapsed))
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.red)
                }
                Spacer()
                if !task.totalSize.isEmpty {
                    Text(task.totalSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // エラー表示
        if task.status == .failed, let error = task.error {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.top, 4)
        }
    }

    // MARK: - メタデータ

    @ViewBuilder
    private var metadataSection: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
            if let duration = task.durationFormatted {
                GridRow {
                    Text(L10n.metadataDuration)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    Text(duration)
                        .font(.callout)
                        .monospacedDigit()
                }
            }

            if let date = task.uploadDateFormatted {
                GridRow {
                    Text(L10n.metadataUploadDate)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(date)
                        .font(.callout)
                }
            }

            if let views = task.viewCountFormatted {
                GridRow {
                    Text(L10n.metadataViewCount)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(views)
                        .font(.callout)
                        .monospacedDigit()
                }
            }

            if let extractor = task.extractor {
                GridRow {
                    Text(L10n.metadataSource)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(extractor)
                        .font(.callout)
                }
            }

            // URL
            GridRow {
                Text("URL")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(task.url)
                    .font(.callout)
                    .foregroundStyle(.blue)
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Helpers

    private var thumbnailURL: URL? {
        guard let urlString = task.thumbnailURL else { return nil }
        return URL(string: urlString)
    }

    @ViewBuilder
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .aspectRatio(16/9, contentMode: .fit)
            .overlay {
                Image(systemName: task.isLiveRecording ? "record.circle" : "play.rectangle")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
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
