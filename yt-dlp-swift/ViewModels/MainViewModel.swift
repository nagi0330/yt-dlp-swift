import Foundation
import SwiftUI

@Observable
class MainViewModel {
    var urlText: String = ""
    var videoInfo: VideoInfo?
    var isFetching = false
    var errorMessage: String?
    var selectedPreset: DownloadPreset = .bestVideo
    var customFormatString: String = ""

    private let ytDlpService = YtDlpService.shared
    private let downloadManager = DownloadManager.shared

    // URLの有効性チェック
    var isValidURL: Bool {
        guard let url = URL(string: urlText) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    // 動画情報を取得
    func fetchVideoInfo() async {
        let url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }

        isFetching = true
        errorMessage = nil
        videoInfo = nil

        do {
            videoInfo = try await ytDlpService.fetchVideoInfo(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isFetching = false
    }

    // ダウンロード開始
    func startDownload() {
        guard let info = videoInfo else { return }

        let formatSelector: String
        if selectedPreset == .custom {
            formatSelector = customFormatString
        } else {
            formatSelector = selectedPreset.formatString
        }

        downloadManager.addTask(
            url: urlText,
            title: info.title,
            formatSelector: formatSelector
        )

        // UIリセット
        urlText = ""
        videoInfo = nil
        errorMessage = nil
    }

    // クリップボードからURL取得
    func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" {
                urlText = trimmed
            }
        }
    }
}
