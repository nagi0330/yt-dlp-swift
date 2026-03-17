import Foundation
import AppKit

@MainActor
@Observable
class DownloadViewModel {
    let downloadManager = DownloadManager.shared
    var selectedTaskID: UUID?

    var tasks: [DownloadTask] {
        downloadManager.tasks
    }

    var selectedTask: DownloadTask? {
        guard let id = selectedTaskID else { return nil }
        return tasks.first { $0.id == id }
    }

    var activeCount: Int {
        tasks.filter { $0.status == .downloading || $0.status == .processing || $0.status == .recording }.count
    }

    var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    func cancelTask(_ task: DownloadTask) {
        downloadManager.cancelTask(task)
    }

    func stopRecording(_ task: DownloadTask) {
        downloadManager.stopRecording(task)
    }

    func resumeTask(_ task: DownloadTask) {
        downloadManager.resumeTask(task)
    }

    func removeTask(_ task: DownloadTask) {
        downloadManager.removeTask(task)
    }

    func clearCompleted() {
        downloadManager.clearCompleted()
    }

    func revealInFinder(_ task: DownloadTask) {
        downloadManager.revealInFinder(task)
    }

    func openFile(_ task: DownloadTask) {
        if let path = task.outputFilePath {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}
