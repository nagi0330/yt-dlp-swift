import Foundation
import AppKit
import UserNotifications

// ダウンロードキューの管理
@MainActor
@Observable
class DownloadManager {
    static let shared = DownloadManager()

    var tasks: [DownloadTask] = []
    private let ytDlpService = YtDlpService.shared
    private var activeTasks = 0

    private static var historyFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("yt-dlp-swift")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("download_history.json")
    }

    init() {
        loadHistory()
    }

    // タスクを追加してキューに入れる
    func addTask(url: String, title: String, thumbnailURL: String? = nil, formatSelector: String, container: String = "", postProcessorArgs: [String] = [], downloadPlaylist: Bool = false, isLiveRecording: Bool = false, liveFromStart: Bool = false, outputTemplate: String? = nil, videoDescription: String? = nil, uploader: String? = nil, duration: Double? = nil, uploadDate: String? = nil, viewCount: Int? = nil, extractor: String? = nil) {
        let task = DownloadTask(
            url: url,
            title: title,
            thumbnailURL: thumbnailURL,
            formatSelector: formatSelector,
            container: container,
            postProcessorArgs: postProcessorArgs,
            downloadPlaylist: downloadPlaylist,
            isLiveRecording: isLiveRecording,
            liveFromStart: liveFromStart,
            outputDirectory: AppSettings.downloadDirectoryURL,
            outputTemplate: outputTemplate ?? AppSettings.outputTemplate,
            videoDescription: videoDescription,
            uploader: uploader,
            duration: duration,
            uploadDate: uploadDate,
            viewCount: viewCount,
            extractor: extractor
        )
        tasks.insert(task, at: 0)
        saveHistory()
        processQueue()
    }

    // キューから次のタスクを処理
    private func processQueue() {
        let maxConcurrent = AppSettings.maxConcurrentDownloads
        guard activeTasks < maxConcurrent else { return }

        guard let task = tasks.first(where: { $0.status == .waiting }) else { return }

        activeTasks += 1
        task.status = task.isLiveRecording ? .recording : .downloading
        if task.isLiveRecording {
            task.phase = .liveRecording
        }

        Task {
            await executeDownload(task)
            activeTasks -= 1
            saveHistory()
            processQueue()
        }
    }

    // ダウンロードを実行
    private func executeDownload(_ task: DownloadTask) async {
        // タイトルがURLのままなら動画情報を取得してタイトル・サムネイル・メタデータを更新
        if task.title == task.url {
            if let info = try? await ytDlpService.fetchVideoInfo(url: task.url) {
                await MainActor.run {
                    task.title = info.title
                    if task.thumbnailURL == nil {
                        task.thumbnailURL = info.thumbnail
                    }
                    task.videoDescription = info.description
                    task.uploader = info.uploader
                    task.duration = info.duration
                    task.uploadDate = info.uploadDate
                    task.viewCount = info.viewCount
                    task.extractor = info.extractor
                }
            }
        }

        // ライブ録画の場合、経過時間タイマーを開始
        var elapsedTimer: Task<Void, Never>?
        if task.isLiveRecording {
            await MainActor.run {
                task.recordingStartTime = Date()
            }
            elapsedTimer = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        if let start = task.recordingStartTime {
                            let elapsed = Date().timeIntervalSince(start)
                            task.recordingElapsed = Self.formatElapsed(elapsed)
                        }
                    }
                }
            }
        }

        do {
            try await ytDlpService.download(
                task: task,
                onProgress: { [weak task] progress in
                    Task { @MainActor in
                        task?.progress = progress.percent / 100.0
                        task?.speed = progress.speed
                        task?.eta = progress.eta
                        task?.totalSize = progress.totalSize
                    }
                },
                onOutput: { [weak task] line in
                    Task { @MainActor in
                        guard let task else { return }
                        // ライブ録画中はフェーズ検出でステータスを上書きしない
                        if let phase = OutputParser.detectPhase(line) {
                            if task.isLiveRecording && phase != .postProcess {
                                // ライブ録画中はliveRecordingフェーズを維持
                            } else {
                                task.phase = phase
                                if phase == .postProcess {
                                    task.status = .processing
                                }
                            }
                        }
                        // ライブ録画のサイズ情報を更新
                        if task.isLiveRecording, let sizeInfo = OutputParser.parseLiveSize(line) {
                            task.totalSize = sizeInfo
                        }
                    }
                },
                onDestination: { [weak task] path in
                    Task { @MainActor in
                        task?.outputFilePath = path
                    }
                }
            )

            elapsedTimer?.cancel()

            await MainActor.run {
                task.status = .completed
                task.progress = 1.0
            }

            // 完了通知
            let notifTitle = task.isLiveRecording ? L10n.recordingComplete : L10n.downloadComplete
            await sendNotification(title: notifTitle, body: task.title)

        } catch {
            elapsedTimer?.cancel()
            await MainActor.run {
                if task.status != .cancelled {
                    task.status = .failed
                    task.error = error.localizedDescription
                }
            }
        }
    }

    // 経過時間フォーマット
    static func formatElapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // タスクをキャンセル
    func cancelTask(_ task: DownloadTask) {
        if let process = task.process, process.isRunning {
            process.interrupt()  // SIGINTでyt-dlpに正常終了を促す
            // 少し待ってもまだ動いていたら強制終了
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if process.isRunning {
                    process.terminate()
                }
            }
        }
        task.status = .cancelled
        task.process = nil
        saveHistory()
    }

    // ライブ録画を正常停止（SIGINTでyt-dlpに終了を伝え、ファイルを正しく閉じる）
    func stopRecording(_ task: DownloadTask) {
        guard task.isLiveRecording, let process = task.process, process.isRunning else { return }
        process.interrupt()  // SIGINTで正常終了 → yt-dlpがファイルを閉じて完了扱いになる
    }

    // タスクを再開
    func resumeTask(_ task: DownloadTask) {
        guard task.status == .cancelled || task.status == .failed else { return }
        task.status = .waiting
        task.error = nil
        task.speed = ""
        task.eta = ""
        task.recordingElapsed = ""
        task.recordingStartTime = nil
        task.phase = task.isLiveRecording ? .liveRecording : .video
        saveHistory()
        processQueue()
    }

    // タスクを削除
    func removeTask(_ task: DownloadTask) {
        if task.status == .downloading || task.status == .processing || task.status == .recording {
            cancelTask(task)
        }
        tasks.removeAll { $0.id == task.id }
        saveHistory()
    }

    // 完了したタスクをすべて削除
    func clearCompleted() {
        tasks.removeAll { $0.status == .completed || $0.status == .cancelled || $0.status == .failed }
        saveHistory()
    }

    // Finderで開く
    func revealInFinder(_ task: DownloadTask) {
        if let path = task.outputFilePath {
            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(task.outputDirectory)
        }
    }

    // MARK: - 履歴の永続化

    private func saveHistory() {
        let records = tasks.map { $0.toRecord() }
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: Self.historyFileURL, options: .atomic)
        } catch {
            print("[DownloadManager] 履歴の保存に失敗: \(error)")
        }
    }

    private func loadHistory() {
        let url = Self.historyFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let records = try JSONDecoder().decode([TaskRecord].self, from: data)
            tasks = records.map { record in
                let task = DownloadTask(record: record)
                // 実行中だったタスクはキャンセル扱いに
                if task.status == .downloading || task.status == .processing || task.status == .waiting || task.status == .recording {
                    task.status = .cancelled
                }
                return task
            }
        } catch {
            print("[DownloadManager] 履歴の読み込みに失敗: \(error)")
        }
    }

    // macOS通知
    private func sendNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
