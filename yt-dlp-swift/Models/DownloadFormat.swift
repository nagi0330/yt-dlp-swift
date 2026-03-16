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
        case .bestVideo: return "最高画質 (動画+音声)"
        case .bestAudio: return "最高音質 (音声のみ)"
        case .video4K: return "4K (2160p)"
        case .video1080p: return "1080p (フルHD)"
        case .video720p: return "720p (HD)"
        case .video480p: return "480p (SD)"
        case .audioMP3: return "MP3 (音声のみ)"
        case .audioM4A: return "M4A (音声のみ)"
        case .audioOpus: return "Opus (音声のみ)"
        case .custom: return "カスタム"
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
        case .mp4: return "MP4 (推奨)"
        case .mkv: return "MKV"
        case .webm: return "WebM"
        }
    }
}
