import Foundation

// yt-dlpのstdout/stderr出力をパースする
enum OutputParser {
    struct ProgressInfo {
        var percent: Double = 0
        var totalSize: String = ""
        var speed: String = ""
        var eta: String = ""
    }

    // 進捗行をパース
    // 例: "[download]  45.2% of 100.00MiB at 5.00MiB/s ETA 00:11"
    // 例: "[download]  45.2% of ~100.00MiB at 5.00MiB/s ETA 00:11"
    static func parseProgress(_ line: String) -> ProgressInfo? {
        guard line.contains("[download]") else { return nil }

        var info = ProgressInfo()

        // パーセンテージ
        if let percentRange = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
            let percentStr = line[percentRange].dropLast() // % を除去
            info.percent = Double(percentStr) ?? 0
        }

        // ファイルサイズ
        if let sizeRange = line.range(of: #"of\s+~?(\S+)"#, options: .regularExpression) {
            let match = String(line[sizeRange])
            info.totalSize = match
                .replacingOccurrences(of: "of ", with: "")
                .replacingOccurrences(of: "~", with: "")
        }

        // 速度
        if let speedRange = line.range(of: #"at\s+(\S+/s)"#, options: .regularExpression) {
            let match = String(line[speedRange])
            info.speed = match.replacingOccurrences(of: "at ", with: "")
        }

        // ETA
        if let etaRange = line.range(of: #"ETA\s+(\S+)"#, options: .regularExpression) {
            let match = String(line[etaRange])
            info.eta = match.replacingOccurrences(of: "ETA ", with: "")
        }

        return info
    }

    // ダウンロード先ファイルパスを検出
    // 例: "[download] Destination: /path/to/file.mp4"
    // 例: "[Merger] Merging formats into "/path/to/file.mp4""
    static func parseDestination(_ line: String) -> String? {
        if line.contains("[download] Destination:") {
            return line.components(separatedBy: "Destination: ").last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if line.contains("[Merger] Merging formats into") {
            let path = line.components(separatedBy: "\"").dropFirst().first
            return path.map { String($0) }
        }
        return nil
    }

    // エラーメッセージを検出
    static func parseError(_ line: String) -> String? {
        if line.contains("ERROR:") {
            return line.components(separatedBy: "ERROR:").last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    // 後処理フェーズを検出
    static func isPostProcessing(_ line: String) -> Bool {
        let postProcessIndicators = [
            "[ExtractAudio]", "[Merger]", "[ffmpeg]",
            "[FixupM3u8]", "[FixupM4a]", "[FixupStretched]",
            "[EmbedThumbnail]", "[EmbedSubtitle]",
        ]
        return postProcessIndicators.contains(where: { line.contains($0) })
    }

    // ダウンロード完了を検出
    static func isDownloadComplete(_ line: String) -> Bool {
        line.contains("[download] 100%") || line.contains("has already been downloaded")
    }
}
