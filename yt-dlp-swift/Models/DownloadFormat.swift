import Foundation

// ユーザーが選択するダウンロードフォーマット
enum DownloadPreset: String, CaseIterable, Identifiable {
    case bestVideo = "best_video"
    case bestAudio = "best_audio"
    case video4K = "video_4k"
    case video1080p = "video_1080p"
    case video720p = "video_720p"
    case video480p = "video_480p"
    case audioMP3 = "audio_mp3"
    case audioM4A = "audio_m4a"
    case audioOpus = "audio_opus"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bestVideo: return L10n.presetBestVideo
        case .bestAudio: return L10n.presetBestAudio
        case .video4K: return L10n.preset4K
        case .video1080p: return L10n.preset1080p
        case .video720p: return L10n.preset720p
        case .video480p: return L10n.preset480p
        case .audioMP3: return L10n.presetMP3
        case .audioM4A: return L10n.presetM4A
        case .audioOpus: return L10n.presetOpus
        case .custom: return L10n.presetCustom
        }
    }

    // yt-dlpの -f オプション文字列
    var formatString: String {
        switch self {
        case .bestVideo: return "bestvideo+bestaudio/best"
        case .bestAudio: return "bestaudio/best"
        case .video4K: return "bestvideo[height<=2160]+bestaudio/best[height<=2160]"
        case .video1080p: return "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
        case .video720p: return "bestvideo[height<=720]+bestaudio/best[height<=720]"
        case .video480p: return "bestvideo[height<=480]+bestaudio/best[height<=480]"
        case .audioMP3: return "bestaudio/best"
        case .audioM4A: return "bestaudio[ext=m4a]/bestaudio/best"
        case .audioOpus: return "bestaudio[ext=webm]/bestaudio/best"
        case .custom: return ""
        }
    }

    var isAudioOnly: Bool {
        switch self {
        case .bestAudio, .audioMP3, .audioM4A, .audioOpus: return true
        default: return false
        }
    }

    /// このプリセットが要求する最小解像度（高さ）。nilなら制限なし
    var requiredHeight: Int? {
        switch self {
        case .video4K: return 2160
        case .video1080p: return 1080
        case .video720p: return 720
        case .video480p: return 480
        default: return nil
        }
    }

    /// 動画情報に基づいてこのプリセットが利用可能か
    func isAvailable(for videoInfo: VideoInfo?) -> Bool {
        guard let info = videoInfo else { return true }
        if let required = requiredHeight {
            return info.hasResolution(required)
        }
        return true
    }

    // 音声のみの場合の後処理オプション
    var postProcessorArgs: [String] {
        switch self {
        case .audioMP3: return ["-x", "--audio-format", "mp3"]
        case .audioM4A: return ["-x", "--audio-format", "m4a"]
        case .audioOpus: return ["-x", "--audio-format", "opus"]
        default: return []
        }
    }
}

enum VideoContainer: String, CaseIterable, Identifiable {
    case mp4 = "mp4"
    case mkv = "mkv"
    case webm = "webm"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mp4: return L10n.containerMP4
        case .mkv: return "MKV"
        case .webm: return "WebM"
        }
    }
}
