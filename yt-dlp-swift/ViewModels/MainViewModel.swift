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
    var showPlaylistAlert = false
    private var pendingPlaylistURL: String?

    private let ytDlpService = YtDlpService.shared
    private let downloadManager = DownloadManager.shared
    private var fetchTask: Task<Void, Never>?

    // URLの有効性チェック
    var isValidURL: Bool {
        guard let url = URL(string: urlText) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    // 動画情報を取得
    func fetchVideoInfo() {
        fetchTask?.cancel()
        fetchTask = Task {
            let url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !url.isEmpty else { return }

            isFetching = true
            errorMessage = nil
            videoInfo = nil

            do {
                let info = try await ytDlpService.fetchVideoInfo(url: url)
                guard !Task.isCancelled else { return }
                videoInfo = info
                // 選択中のプリセットが利用不可なら自動で最適なものに変更
                if !selectedPreset.isAvailable(for: info) {
                    autoSelectBestPreset(for: info)
                }
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }

            isFetching = false
        }
    }

    // 取得をキャンセル
    func cancelFetch() {
        fetchTask?.cancel()
        fetchTask = nil
        isFetching = false
        errorMessage = nil
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

        let behavior = PlaylistBehavior(rawValue: AppSettings.playlistBehavior) ?? .ask
        let usePlaylist = behavior == .entirePlaylist && looksLikePlaylist(urlText)

        downloadManager.addTask(
            url: urlText,
            title: info.title,
            thumbnailURL: info.thumbnail,
            formatSelector: formatSelector,
            container: AppSettings.preferredContainer,
            postProcessorArgs: selectedPreset.postProcessorArgs,
            downloadPlaylist: usePlaylist
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
        // スペースまたは改行で区切ってURLを抽出
        urlText
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { token in
                guard let url = URL(string: token) else { return false }
                return url.scheme == "http" || url.scheme == "https"
            }
    }

    var isBulkMode: Bool {
        bulkURLs.count >= 2
    }

    // プレイリストURLかどうかを簡易判定
    private func looksLikePlaylist(_ url: String) -> Bool {
        // YouTube playlist
        if url.contains("list=") && (url.contains("youtube.com") || url.contains("youtu.be")) {
            return true
        }
        // 一般的なプレイリストパターン
        if url.contains("/playlist") || url.contains("/sets/") || url.contains("/album/") {
            return true
        }
        return false
    }

    // 情報取得をスキップして即DL（デフォルト設定を使用）
    func quickDownload() {
        let url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }

        let behavior = PlaylistBehavior(rawValue: AppSettings.playlistBehavior) ?? .ask

        if looksLikePlaylist(url) && behavior == .ask {
            pendingPlaylistURL = url
            showPlaylistAlert = true
            return
        }

        let usePlaylist = behavior == .entirePlaylist && looksLikePlaylist(url)
        addQuickDownloadTask(url: url, downloadPlaylist: usePlaylist)
    }

    // プレイリスト確認後の処理
    func confirmPlaylistChoice(downloadPlaylist: Bool) {
        guard let url = pendingPlaylistURL else { return }
        addQuickDownloadTask(url: url, downloadPlaylist: downloadPlaylist)
        pendingPlaylistURL = nil
    }

    private func addQuickDownloadTask(url: String, downloadPlaylist: Bool) {
        let preset = DownloadPreset.allCases.first { $0.rawValue == AppSettings.defaultPreset } ?? .bestVideo

        downloadManager.addTask(
            url: url,
            title: url,
            formatSelector: preset.formatString,
            container: AppSettings.preferredContainer,
            postProcessorArgs: preset.postProcessorArgs,
            downloadPlaylist: downloadPlaylist
        )

        // UIリセット
        urlText = ""
        videoInfo = nil
        errorMessage = nil
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
                formatSelector: formatSelector,
                container: AppSettings.preferredContainer,
                postProcessorArgs: preset.postProcessorArgs
            )
        }

        // UIリセット
        urlText = ""
        videoInfo = nil
        errorMessage = nil
    }
}
