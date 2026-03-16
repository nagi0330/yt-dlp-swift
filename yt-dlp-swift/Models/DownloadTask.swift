import Foundation

@Observable
class DownloadTask: Identifiable {
    let id: UUID
    let url: String
    var title: String
    var thumbnailURL: String?
    let formatSelector: String
    let container: String          // merge-output-format (mp4/mkv/webm)
    let postProcessorArgs: [String] // 音声抽出用 (-x --audio-format mp3 等)
    let downloadPlaylist: Bool     // true: --yes-playlist, false: --no-playlist
    let outputDirectory: URL
    let outputTemplate: String
    let createdAt: Date

    var status: DownloadStatus = .waiting
    var phase: DownloadPhase = .video
    var progress: Double = 0  // 0.0 ~ 1.0
    var speed: String = ""
    var eta: String = ""
    var downloadedSize: String = ""
    var totalSize: String = ""
    var outputFilePath: String?
    var error: String?

    // Process制御用（永続化しない）
    var process: Process?

    init(url: String, title: String, thumbnailURL: String? = nil, formatSelector: String, container: String = "", postProcessorArgs: [String] = [], downloadPlaylist: Bool = false, outputDirectory: URL, outputTemplate: String) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.formatSelector = formatSelector
        self.container = container
        self.postProcessorArgs = postProcessorArgs
        self.downloadPlaylist = downloadPlaylist
        self.outputDirectory = outputDirectory
        self.outputTemplate = outputTemplate
        self.createdAt = Date()
    }

    // 永続化用の復元イニシャライザ
    init(record: TaskRecord) {
        self.id = record.id
        self.url = record.url
        self.title = record.title
        self.thumbnailURL = record.thumbnailURL
        self.formatSelector = record.formatSelector
        self.container = record.container ?? ""
        self.postProcessorArgs = record.postProcessorArgs ?? []
        self.downloadPlaylist = record.downloadPlaylist ?? false
        self.outputDirectory = URL(fileURLWithPath: record.outputDirectoryPath)
        self.outputTemplate = record.outputTemplate
        self.createdAt = record.createdAt
        self.status = DownloadStatus.from(record.status)
        self.progress = record.progress
        self.outputFilePath = record.outputFilePath
        self.error = record.error
    }

    func toRecord() -> TaskRecord {
        TaskRecord(
            id: id,
            url: url,
            title: title,
            thumbnailURL: thumbnailURL,
            formatSelector: formatSelector,
            container: container,
            postProcessorArgs: postProcessorArgs,
            downloadPlaylist: downloadPlaylist,
            outputDirectoryPath: outputDirectory.path,
            outputTemplate: outputTemplate,
            createdAt: createdAt,
            status: status.rawValue,
            progress: progress,
            outputFilePath: outputFilePath,
            error: error
        )
    }
}

// Codable用の構造体（@Observableクラスは直接Codableにできないため）
struct TaskRecord: Codable {
    let id: UUID
    let url: String
    let title: String
    let thumbnailURL: String?
    let formatSelector: String
    let container: String?
    let postProcessorArgs: [String]?
    let downloadPlaylist: Bool?
    let outputDirectoryPath: String
    let outputTemplate: String
    let createdAt: Date
    let status: String
    let progress: Double
    let outputFilePath: String?
    let error: String?
}

enum DownloadStatus: String {
    case waiting = "waiting"
    case downloading = "downloading"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case paused = "paused"

    var displayName: String {
        switch self {
        case .waiting: return L10n.statusWaiting
        case .downloading: return L10n.statusDownloading
        case .processing: return L10n.statusProcessing
        case .completed: return L10n.statusCompleted
        case .failed: return L10n.statusFailed
        case .cancelled: return L10n.statusCancelled
        case .paused: return L10n.statusPaused
        }
    }

    /// 旧日本語rawValueからの互換変換
    static func from(_ raw: String) -> DownloadStatus {
        if let status = DownloadStatus(rawValue: raw) { return status }
        // 旧日本語rawValueのマイグレーション
        switch raw {
        case "待機中": return .waiting
        case "ダウンロード中": return .downloading
        case "処理中": return .processing
        case "完了": return .completed
        case "エラー": return .failed
        case "キャンセル": return .cancelled
        case "一時停止": return .paused
        default: return .cancelled
        }
    }
}

enum DownloadPhase: String {
    case video = "video"
    case audio = "audio"
    case postProcess = "postProcess"

    var displayName: String {
        switch self {
        case .video: return L10n.phaseVideo
        case .audio: return L10n.phaseAudio
        case .postProcess: return L10n.phasePostProcess
        }
    }
}
