import Foundation

// 日本語ファイル名のサニタイズ
enum FileNameSanitizer {
    // macOS APFS/HFS+で使えない文字を除去
    private static let invalidCharacters = CharacterSet(charactersIn: "/:\0")

    static func sanitize(_ fileName: String) -> String {
        var sanitized = fileName

        // 無効な文字を置換
        sanitized = sanitized.unicodeScalars
            .filter { !invalidCharacters.contains($0) }
            .map { String($0) }
            .joined()

        // 先頭・末尾の空白とドットを除去
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        // 空文字列の場合はデフォルト名
        if sanitized.isEmpty {
            sanitized = "untitled"
        }

        // NFCに正規化 (macOS APFS)
        sanitized = sanitized.precomposedStringWithCanonicalMapping

        return sanitized
    }

    // 長すぎるファイル名を省略
    static func truncate(_ fileName: String, maxLength: Int = 200) -> String {
        guard fileName.count > maxLength else { return fileName }
        let ext = (fileName as NSString).pathExtension
        let name = (fileName as NSString).deletingPathExtension
        let maxNameLength = maxLength - ext.count - 1
        let truncated = String(name.prefix(maxNameLength))
        return ext.isEmpty ? truncated : "\(truncated).\(ext)"
    }
}
