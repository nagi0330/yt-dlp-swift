import Foundation

@Observable
class DownloadViewModel {
    let downloadManager = DownloadManager.shared

    var tasks: [DownloadTask] {
        downloadManager.tasks
    }

    var activeCount: Int {
        tasks.filter { $0.status == .downloading || $0.status == .processing }.count
    }

    var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    func cancelTask(_ task: DownloadTask) {
        downloadManager.cancelTask(task)
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
}
