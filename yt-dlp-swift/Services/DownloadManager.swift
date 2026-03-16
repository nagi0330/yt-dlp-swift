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
    func addTask(url: String, title: String, thumbnailURL: String? = nil, formatSelector: String, container: String = "", postProcessorArgs: [String] = [], downloadPlaylist: Bool = false, outputTemplate: String? = nil) {
        let task = DownloadTask(
            url: url,
            title: title,
            thumbnailURL: thumbnailURL,
            formatSelector: formatSelector,
            container: container,
            postProcessorArgs: postProcessorArgs,
            downloadPlaylist: downloadPlaylist,
            outputDirectory: AppSettings.downloadDirectoryURL,
            outputTemplate: outputTemplate ?? AppSettings.outputTemplate
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
        task.status = .downloading

        Task {
            await executeDownload(task)
            activeTasks -= 1
            saveHistory()
            processQueue()
        }
    }

    // ダウンロードを実行
    private func executeDownload(_ task: DownloadTask) async {
        // タイトルがURLのままなら動画情報を取得してタイトル・サムネイルを更新
        if task.title == task.url {
            if let info = try? await ytDlpService.fetchVideoInfo(url: task.url) {
                await MainActor.run {
                    task.title = info.title
                    if task.thumbnailURL == nil {
                        task.thumbnailURL = info.thumbnail
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
                        if let phase = OutputParser.detectPhase(line) {
                            task?.phase = phase
                            if phase == .postProcess {
                                task?.status = .processing
                            }
                        }
                    }
                },
                onDestination: { [weak task] path in
                    Task { @MainActor in
                        task?.outputFilePath = path
                    }
                }
            )

            await MainActor.run {
                task.status = .completed
                task.progress = 1.0
            }

            // 完了通知
            await sendNotification(title: L10n.downloadComplete, body: task.title)

        } catch {
            await MainActor.run {
                if task.status != .cancelled {
                    task.status = .failed
                    task.error = error.localizedDescription
                }
            }
        }
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

    // タスクを再開
    func resumeTask(_ task: DownloadTask) {
        guard task.status == .cancelled || task.status == .failed else { return }
        task.status = .waiting
        task.error = nil
        task.speed = ""
        task.eta = ""
        task.phase = .video
        saveHistory()
        processQueue()
    }

    // タスクを削除
    func removeTask(_ task: DownloadTask) {
        if task.status == .downloading || task.status == .processing {
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
                if task.status == .downloading || task.status == .processing || task.status == .waiting {
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
