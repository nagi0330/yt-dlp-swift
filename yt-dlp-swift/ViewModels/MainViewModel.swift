import Foundation
import SwiftUI

@MainActor
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
            // 選択中のプリセットが利用不可なら自動で最適なものに変更
            if let info = videoInfo, !selectedPreset.isAvailable(for: info) {
                autoSelectBestPreset(for: info)
            }
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

    // 利用可能な最高画質プリセットを自動選択
    private func autoSelectBestPreset(for info: VideoInfo) {
        let videoPresets: [DownloadPreset] = [.bestVideo, .video4K, .video1080p, .video720p, .video480p]
        for preset in videoPresets {
            if preset.isAvailable(for: info) {
                selectedPreset = preset
                return
            }
        }
        selectedPreset = .bestVideo
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

    // 複数URLを検出して一括ダウンロード
    // テキストからURLを抽出し、2つ以上あれば一括DLを提案
    var bulkURLs: [String] {
        urlText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                guard let url = URL(string: line) else { return false }
                return url.scheme == "http" || url.scheme == "https"
            }
    }

    var isBulkMode: Bool {
        bulkURLs.count >= 2
    }

    // 一括ダウンロード（デフォルト設定を使用）
    func startBulkDownload() {
        let urls = bulkURLs
        guard !urls.isEmpty else { return }

        let preset = DownloadPreset.allCases.first { $0.rawValue == AppSettings.defaultPreset } ?? .bestVideo
        let formatSelector = preset.formatString

        for url in urls {
            // URLからタイトルを仮設定（後でyt-dlpが取得する）
            downloadManager.addTask(
                url: url,
                title: url,
                formatSelector: formatSelector
            )
        }

        // UIリセット
        urlText = ""
        videoInfo = nil
        errorMessage = nil
    }
}
