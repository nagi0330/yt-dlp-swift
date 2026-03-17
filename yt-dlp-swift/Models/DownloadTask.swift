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

    // メタデータ（VideoInfoから取得）
    var videoDescription: String?
    var uploader: String?
    var duration: Double?
    var uploadDate: String?
    var viewCount: Int?
    var extractor: String?

    // ライブ録画関連
    let isLiveRecording: Bool
    let liveFromStart: Bool       // --live-from-start を使うか
    var recordingStartTime: Date? // 録画開始時刻
    var recordingElapsed: String = "" // 経過時間表示用

    // Process制御用（永続化しない）
    var process: Process?

    init(url: String, title: String, thumbnailURL: String? = nil, formatSelector: String, container: String = "", postProcessorArgs: [String] = [], downloadPlaylist: Bool = false, isLiveRecording: Bool = false, liveFromStart: Bool = false, outputDirectory: URL, outputTemplate: String, videoDescription: String? = nil, uploader: String? = nil, duration: Double? = nil, uploadDate: String? = nil, viewCount: Int? = nil, extractor: String? = nil) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.formatSelector = formatSelector
        self.container = container
        self.postProcessorArgs = postProcessorArgs
        self.downloadPlaylist = downloadPlaylist
        self.isLiveRecording = isLiveRecording
        self.liveFromStart = liveFromStart
        self.outputDirectory = outputDirectory
        self.outputTemplate = outputTemplate
        self.createdAt = Date()
        self.videoDescription = videoDescription
        self.uploader = uploader
        self.duration = duration
        self.uploadDate = uploadDate
        self.viewCount = viewCount
        self.extractor = extractor
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
        self.isLiveRecording = record.isLiveRecording ?? false
        self.liveFromStart = record.liveFromStart ?? false
        self.outputDirectory = URL(fileURLWithPath: record.outputDirectoryPath)
        self.outputTemplate = record.outputTemplate
        self.createdAt = record.createdAt
        self.status = DownloadStatus.from(record.status)
        self.progress = record.progress
        self.outputFilePath = record.outputFilePath
        self.error = record.error
        self.videoDescription = record.videoDescription
        self.uploader = record.uploader
        self.duration = record.duration
        self.uploadDate = record.uploadDate
        self.viewCount = record.viewCount
        self.extractor = record.extractor
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
            isLiveRecording: isLiveRecording,
            liveFromStart: liveFromStart,
            outputDirectoryPath: outputDirectory.path,
            outputTemplate: outputTemplate,
            createdAt: createdAt,
            status: status.rawValue,
            progress: progress,
            outputFilePath: outputFilePath,
            error: error,
            videoDescription: videoDescription,
            uploader: uploader,
            duration: duration,
            uploadDate: uploadDate,
            viewCount: viewCount,
            extractor: extractor
        )
    }

    // 再生時間を "HH:MM:SS" 形式に変換
    var durationFormatted: String? {
        guard let duration = duration else { return nil }
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // アップロード日を "yyyy年MM月dd日" 形式に変換
    var uploadDateFormatted: String? {
        guard let uploadDate = uploadDate, uploadDate.count == 8 else { return nil }
        let year = String(uploadDate.prefix(4))
        let month = String(uploadDate.dropFirst(4).prefix(2))
        let day = String(uploadDate.dropFirst(6).prefix(2))
        return L10n.uploadDate(year: year, month: month, day: day)
    }

    // 再生回数をフォーマット
    var viewCountFormatted: String? {
        guard let count = viewCount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count))
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
    let isLiveRecording: Bool?
    let liveFromStart: Bool?
    let outputDirectoryPath: String
    let outputTemplate: String
    let createdAt: Date
    let status: String
    let progress: Double
    let outputFilePath: String?
    let error: String?
    let videoDescription: String?
    let uploader: String?
    let duration: Double?
    let uploadDate: String?
    let viewCount: Int?
    let extractor: String?
}

enum DownloadStatus: String {
    case waiting = "waiting"
    case downloading = "downloading"
    case recording = "recording"    // ライブ録画中
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case paused = "paused"

    var displayName: String {
        switch self {
        case .waiting: return L10n.statusWaiting
        case .downloading: return L10n.statusDownloading
        case .recording: return L10n.statusRecording
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
    case liveRecording = "liveRecording"

    var displayName: String {
        switch self {
        case .video: return L10n.phaseVideo
        case .audio: return L10n.phaseAudio
        case .postProcess: return L10n.phasePostProcess
        case .liveRecording: return L10n.phaseLiveRecording
        }
    }
}
