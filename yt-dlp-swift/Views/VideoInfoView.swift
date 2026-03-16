import SwiftUI

struct VideoInfoView: View {
    let videoInfo: VideoInfo
    var onStartDownload: (() -> Void)?
    var onStartRecording: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // サムネイル
            ZStack(alignment: .topLeading) {
                if let thumbnailURL = videoInfo.thumbnail, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            thumbnailPlaceholder
                        case .empty:
                            ProgressView()
                                .frame(width: 280, height: 157)
                        @unknown default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    thumbnailPlaceholder
                }

                // ライブバッジ
                if videoInfo.isCurrentlyLive {
                    liveBadge
                } else if videoInfo.isScheduled {
                    upcomingBadge
                }
            }

            // 動画情報
            VStack(alignment: .leading, spacing: 8) {
                Text(videoInfo.title)
                    .font(.headline)
                    .lineLimit(3)

                if let uploader = videoInfo.uploader {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        Text(uploader)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    if videoInfo.isCurrentlyLive {
                        Label(L10n.liveBadge, systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.red)
                    } else {
                        Label(videoInfo.durationFormatted, systemImage: "clock")
                            .foregroundStyle(.secondary)
                    }

                    if let date = videoInfo.uploadDateFormatted {
                        Label(date, systemImage: "calendar")
                            .foregroundStyle(.secondary)
                    }

                    if let views = videoInfo.viewCount {
                        Label(formatCount(views), systemImage: "eye")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)

                HStack(spacing: 6) {
                    if let extractor = videoInfo.extractor {
                        Text(extractor)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1), in: Capsule())
                            .foregroundStyle(.blue)
                    }

                    if videoInfo.isCurrentlyLive {
                        Text(L10n.liveStreamDetected)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1), in: Capsule())
                            .foregroundStyle(.red)
                    }
                }

                // アクションボタン
                HStack {
                    if let formats = videoInfo.formats {
                        let videoFormats = formats.filter { $0.hasVideo }
                        let audioFormats = formats.filter { $0.hasAudio && !$0.hasVideo }
                        Text(L10n.formatCount(video: videoFormats.count, audio: audioFormats.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let recordAction = onStartRecording {
                        Button {
                            recordAction()
                        } label: {
                            Label(L10n.startRecording, systemImage: "record.circle")
                                .font(.body)
                        }
                        .tint(.red)
                        .controlSize(.large)
                        .keyboardShortcut("r", modifiers: .command)
                    }

                    if let action = onStartDownload {
                        Button {
                            action()
                        } label: {
                            Label(L10n.startDownload, systemImage: "arrow.down.circle.fill")
                                .font(.body)
                        }
                        .controlSize(.large)
                        .keyboardShortcut("d", modifiers: .command)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(width: 280, height: 157)
            .overlay {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }
    }

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
            Text(L10n.liveBadge)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.red, in: Capsule())
        .foregroundStyle(.white)
        .padding(8)
    }

    private var upcomingBadge: some View {
        Text(L10n.upcomingBadge)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange, in: Capsule())
            .foregroundStyle(.white)
            .padding(8)
    }

    private func formatCount(_ count: Int) -> String {
        L10n.viewCount(count)
    }
}
