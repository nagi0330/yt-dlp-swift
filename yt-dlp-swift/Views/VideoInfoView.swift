import SwiftUI

struct VideoInfoView: View {
    let videoInfo: VideoInfo

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // サムネイル
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
                    Label(videoInfo.durationFormatted, systemImage: "clock")
                        .foregroundStyle(.secondary)

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

                if let extractor = videoInfo.extractor {
                    Text(extractor)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }

                // 利用可能なフォーマット数
                if let formats = videoInfo.formats {
                    let videoFormats = formats.filter { $0.hasVideo }
                    let audioFormats = formats.filter { $0.hasAudio && !$0.hasVideo }
                    Text(L10n.formatCount(video: videoFormats.count, audio: audioFormats.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private func formatCount(_ count: Int) -> String {
        L10n.viewCount(count)
    }
}
