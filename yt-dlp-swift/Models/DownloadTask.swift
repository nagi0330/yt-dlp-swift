import Foundation

@Observable
class DownloadTask: Identifiable {
    let id = UUID()
    let url: String
    let title: String
    let formatSelector: String
    let outputDirectory: URL
    let outputTemplate: String

    var status: DownloadStatus = .waiting
    var progress: Double = 0  // 0.0 ~ 1.0
    var speed: String = ""
    var eta: String = ""
    var downloadedSize: String = ""
    var totalSize: String = ""
    var outputFilePath: String?
    var error: String?

    // Process制御用
    var process: Process?

    init(url: String, title: String, formatSelector: String, outputDirectory: URL, outputTemplate: String) {
        self.url = url
        self.title = title
        self.formatSelector = formatSelector
        self.outputDirectory = outputDirectory
        self.outputTemplate = outputTemplate
    }
}

enum DownloadStatus: String {
    case waiting = "待機中"
    case downloading = "ダウンロード中"
    case processing = "処理中"
    case completed = "完了"
    case failed = "エラー"
    case cancelled = "キャンセル"
    case paused = "一時停止"
}
