import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("yt-dlp-swift")
                .font(.title)
                .fontWeight(.bold)

            Text("バージョン 1.0.0")
                .foregroundStyle(.secondary)

            Text("macOS向け yt-dlp GUIアプリケーション")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 4) {
                Text("MIT License")
                    .font(.caption)
                Text("yt-dlp, FFmpeg, Deno はそれぞれのライセンスに基づきます")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(width: 400)
    }
}
