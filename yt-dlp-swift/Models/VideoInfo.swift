import Foundation

// yt-dlp --dump-json の出力をデコードするモデル
struct VideoInfo: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnail: String?
    let duration: Double?
    let uploader: String?
    let uploaderURL: String?
    let viewCount: Int?
    let likeCount: Int?
    let uploadDate: String?
    let webpage_url: String?
    let extractor: String?
    let formats: [VideoFormat]?
    let requestedFormats: [VideoFormat]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, thumbnail, duration
        case uploader
        case uploaderURL = "uploader_url"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case uploadDate = "upload_date"
        case webpage_url, extractor, formats
        case requestedFormats = "requested_formats"
    }

    // 再生時間を "HH:MM:SS" 形式に変換
    var durationFormatted: String {
        guard let duration = duration else { return L10n.unknown }
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

    /// 利用可能な最大解像度（高さ）
    var maxHeight: Int? {
        formats?.filter { $0.hasVideo }.compactMap { $0.height }.max()
    }

    /// 利用可能な解像度一覧（高さの降順）
    var availableHeights: [Int] {
        guard let formats = formats else { return [] }
        let heights = Set(formats.filter { $0.hasVideo }.compactMap { $0.height })
        return heights.sorted(by: >)
    }

    /// 指定解像度が利用可能か
    func hasResolution(_ height: Int) -> Bool {
        availableHeights.contains { $0 >= height }
    }

    /// 音声フォーマットが利用可能か
    var hasAudioFormats: Bool {
        formats?.contains { $0.hasAudio } ?? false
    }
}

struct VideoFormat: Identifiable, Codable {
    var id: String { formatID }
    let formatID: String
    let formatNote: String?
    let ext: String?
    let resolution: String?
    let width: Int?
    let height: Int?
    let fps: Double?
    let vcodec: String?
    let acodec: String?
    let filesize: Int?
    let filesizeApprox: Int?
    let tbr: Double?
    let abr: Double?
    let vbr: Double?

    enum CodingKeys: String, CodingKey {
        case formatID = "format_id"
        case formatNote = "format_note"
        case ext, resolution, width, height, fps
        case vcodec, acodec, filesize
        case filesizeApprox = "filesize_approx"
        case tbr, abr, vbr
    }

    var hasVideo: Bool {
        vcodec != nil && vcodec != "none"
    }

    var hasAudio: Bool {
        acodec != nil && acodec != "none"
    }

    var filesizeFormatted: String? {
        let size = filesize ?? filesizeApprox
        guard let size = size else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    var qualityLabel: String {
        if let height = height, hasVideo {
            let p = "\(height)p"
            if let fps = fps, fps > 30 {
                return "\(p)\(Int(fps))"
            }
            return p
        }
        if let abr = abr {
            return "\(Int(abr))kbps"
        }
        return formatNote ?? formatID
    }
}
