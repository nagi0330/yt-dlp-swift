import Foundation
import AppKit
import UserNotifications

// ダウンロードキューの管理
@Observable
class DownloadManager {
    static let shared = DownloadManager()

    var tasks: [DownloadTask] = []
    private let ytDlpService = YtDlpService.shared
    private var activeTasks = 0

    // タスクを追加してキューに入れる
    func addTask(url: String, title: String, formatSelector: String, outputTemplate: String? = nil) {
        let task = DownloadTask(
            url: url,
            title: title,
            formatSelector: formatSelector,
            outputDirectory: AppSettings.downloadDirectoryURL,
            outputTemplate: outputTemplate ?? AppSettings.outputTemplate
        )
        tasks.insert(task, at: 0)
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
            processQueue()
        }
    }

    // ダウンロードを実行
    private func executeDownload(_ task: DownloadTask) async {
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
                        if OutputParser.isPostProcessing(line) {
                            task?.status = .processing
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
            await sendNotification(title: "ダウンロード完了", body: task.title)

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
        task.process?.terminate()
        task.status = .cancelled
    }

    // タスクを削除
    func removeTask(_ task: DownloadTask) {
        if task.status == .downloading || task.status == .processing {
            cancelTask(task)
        }
        tasks.removeAll { $0.id == task.id }
    }

    // 完了したタスクをすべて削除
    func clearCompleted() {
        tasks.removeAll { $0.status == .completed || $0.status == .cancelled || $0.status == .failed }
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
