import Foundation

// 依存バイナリの管理
enum Dependency: String, CaseIterable, Identifiable {
    case ytDlp = "yt-dlp"
    case ffmpeg = "ffmpeg"
    case ffprobe = "ffprobe"
    case deno = "deno"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ytDlp: return L10n.depYtDlp
        case .ffmpeg: return L10n.depFFmpeg
        case .ffprobe: return L10n.depFFprobe
        case .deno: return L10n.depDeno
        }
    }

    var binaryName: String { rawValue }
}

enum DependencyError: LocalizedError {
    case notInstalled(Dependency)
    case downloadFailed(Dependency, String)
    case installFailed(Dependency, String)

    var errorDescription: String? {
        switch self {
        case .notInstalled(let dep): return L10n.depNotInstalled(dep.displayName)
        case .downloadFailed(let dep, let msg): return L10n.depDownloadFailed(dep.displayName, msg)
        case .installFailed(let dep, let msg): return L10n.depInstallFailed(dep.displayName, msg)
        }
    }
}

struct DependencyStatus: Identifiable {
    var id: String { dependency.id }
    let dependency: Dependency
    var isInstalled: Bool = false
    var version: String?
    var latestVersion: String?
    var path: URL?
    var isUpdating: Bool = false
    var isCheckingVersion: Bool = false    // ローカルバージョン取得中
    var isCheckingUpdate: Bool = false     // 最新バージョン確認中

    var canCheckVersion: Bool { true }

    var isLatest: Bool {
        guard let version = version, let latest = latestVersion else { return false }
        // ローカル "2.7.5 (stable, ...)" に latest "2.7.5" が含まれるか等
        return version == latest || version.hasPrefix(latest + " ") || version.hasPrefix(latest + "-")
    }
}

@Observable
class DependencyManager {
    static let shared = DependencyManager()

    // グローバルインストール先
    let globalBinDirectory = URL(fileURLWithPath: "/usr/local/bin")

    // 検索パス (優先順)
    private let searchPaths = [
        "/usr/local/bin",
        "/opt/homebrew/bin",
        "/usr/bin",
    ]

    // 依存バイナリのパスを解決
    func resolveBinaryPath(for dependency: Dependency) -> URL? {
        for dir in searchPaths {
            let path = "\(dir)/\(dependency.binaryName)"
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        // whichコマンドで探す
        if let path = findBinaryWithWhich(dependency.binaryName) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    private func findBinaryWithWhich(_ name: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let output = output, !output.isEmpty, process.terminationStatus == 0 {
                return output
            }
        } catch {}
        return nil
    }

    // バージョン取得
    func getVersion(for dependency: Dependency) async -> String? {
        guard let binaryPath = resolveBinaryPath(for: dependency) else { return nil }

        let args: [String]
        switch dependency {
        case .ytDlp: args = ["--version"]
        case .ffmpeg, .ffprobe: args = ["-version"]
        case .deno: args = ["--version"]
        }

        do {
            let result = try await ProcessRunner.run(executableURL: binaryPath, arguments: args)
            if result.exitCode == 0 {
                let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                if dependency == .ffmpeg || dependency == .ffprobe {
                    // "ffmpeg version 8.0 Copyright..." → "8.0"
                    if let firstLine = output.components(separatedBy: "\n").first {
                        let parts = firstLine.components(separatedBy: " ")
                        if let vIdx = parts.firstIndex(of: "version"), vIdx + 1 < parts.count {
                            return parts[vIdx + 1]
                        }
                        return firstLine
                    }
                }
                if dependency == .deno {
                    if let firstLine = output.components(separatedBy: "\n").first {
                        return firstLine.replacingOccurrences(of: "deno ", with: "")
                    }
                }
                return output
            }
        } catch {}
        return nil
    }

    // GitHub から最新バージョンを取得
    func getLatestVersionTag(for dependency: Dependency) async -> String? {
        switch dependency {
        case .ffmpeg, .ffprobe:
            return await getLatestFFmpegVersion()
        default:
            break
        }

        let repo: String
        switch dependency {
        case .ytDlp: repo = "yt-dlp/yt-dlp"
        case .deno: repo = "denoland/deno"
        default: return nil
        }

        do {
            let apiURL = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
            var request = URLRequest(url: apiURL)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let tag = release.tagName
            return tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        } catch {
            return nil
        }
    }

    // FFmpeg/FFmpegのタグから最新安定版を取得
    // タグ形式: "nX.Y" (安定) / "nX.Y-dev" (開発) / "nX.Y.Z" (パッチ)
    private func getLatestFFmpegVersion() async -> String? {
        struct GitHubTag: Codable {
            let name: String
        }

        do {
            let apiURL = URL(string: "https://api.github.com/repos/FFmpeg/FFmpeg/tags?per_page=30")!
            var request = URLRequest(url: apiURL)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let tags = try JSONDecoder().decode([GitHubTag].self, from: data)

            // "nX.Y" or "nX.Y.Z" (devを除外) の最新を探す
            let stableTags = tags
                .map { $0.name }
                .filter { $0.hasPrefix("n") && !$0.contains("dev") }
                .sorted { compareVersions($0, $1) }

            guard let latest = stableTags.last else { return nil }
            // "n8.0" → "8.0", "n8.0.1" → "8.0.1"
            return String(latest.dropFirst())
        } catch {
            return nil
        }
    }

    // バージョン文字列の比較 ("n8.0" < "n8.0.1" < "n8.1")
    private func compareVersions(_ a: String, _ b: String) -> Bool {
        let aParts = a.dropFirst().split(separator: ".").compactMap { Int($0) }
        let bParts = b.dropFirst().split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(aParts.count, bParts.count) {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av != bv { return av < bv }
        }
        return false
    }

    // MARK: - ダウンロード（URLSession + 進捗コールバック）

    /// URLからファイルをダウンロードし、進捗をコールバックで通知
    func downloadWithProgress(
        from url: URL,
        to destination: URL,
        onProgress: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let delegate = DownloadProgressDelegate(
                onProgress: onProgress,
                destination: destination,
                continuation: continuation
            )
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.timeoutInterval = 300
            session.downloadTask(with: request).resume()
        }
    }

    // MARK: - ダウンロードURL解決

    struct EvermeetInfo: Codable {
        let version: String
        let download: EvermeetDownload
    }
    struct EvermeetDownload: Codable {
        let zip: EvermeetFile
    }
    struct EvermeetFile: Codable {
        let url: String
    }

    /// 各依存のダウンロードURLを解決
    func resolveDownloadURL(for dependency: Dependency) async throws -> URL {
        let arch = ProcessInfo.processInfo.machineArchitecture

        switch dependency {
        case .ytDlp:
            let assets = try await getLatestReleaseAssets(repo: "yt-dlp/yt-dlp")
            guard let asset = assets.first(where: { $0.name == "yt-dlp_macos" }),
                  let url = URL(string: asset.downloadURL) else {
                throw DependencyError.downloadFailed(.ytDlp, "Download URL not found")
            }
            return url

        case .ffmpeg:
            let apiURL = URL(string: "https://evermeet.cx/ffmpeg/info/ffmpeg/release")!
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let info = try JSONDecoder().decode(EvermeetInfo.self, from: data)
            guard let url = URL(string: info.download.zip.url) else {
                throw DependencyError.downloadFailed(.ffmpeg, "Download URL not found")
            }
            return url

        case .ffprobe:
            let apiURL = URL(string: "https://evermeet.cx/ffmpeg/info/ffprobe/release")!
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let info = try JSONDecoder().decode(EvermeetInfo.self, from: data)
            guard let url = URL(string: info.download.zip.url) else {
                throw DependencyError.downloadFailed(.ffprobe, "Download URL not found")
            }
            return url

        case .deno:
            let assetName = arch == "arm64" ? "deno-aarch64-apple-darwin.zip" : "deno-x86_64-apple-darwin.zip"
            let assets = try await getLatestReleaseAssets(repo: "denoland/deno")
            guard let asset = assets.first(where: { $0.name == assetName }),
                  let url = URL(string: asset.downloadURL) else {
                throw DependencyError.downloadFailed(.deno, "Download URL not found")
            }
            return url
        }
    }

    // MARK: - インストール（ダウンロード済みファイルを配置）

    /// ダウンロード済みファイルをインストール先に配置
    func installDownloaded(dependency: Dependency, downloadedFile: URL) throws {
        let binDir = globalBinDirectory.path

        // /usr/local/bin の存在・権限チェック
        let fm = FileManager.default
        if !fm.fileExists(atPath: binDir) {
            try fm.createDirectory(atPath: binDir, withIntermediateDirectories: true)
        }

        switch dependency {
        case .ytDlp:
            let dest = "\(binDir)/yt-dlp"
            try? fm.removeItem(atPath: dest)
            try fm.copyItem(at: downloadedFile, to: URL(fileURLWithPath: dest))
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest)

        case .ffmpeg, .ffprobe:
            // zipを展開してバイナリをコピー
            let tmpDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: tmpDir) }

            let unzipResult = try runSync(
                executable: "/usr/bin/unzip",
                arguments: ["-oq", downloadedFile.path, "-d", tmpDir.path]
            )
            guard unzipResult == 0 else {
                throw DependencyError.installFailed(dependency, "Extraction failed")
            }

            let binaryName = dependency.binaryName
            let dest = "\(binDir)/\(binaryName)"
            // unzip先からバイナリを探す
            if let binary = try fm.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil)
                .first(where: { $0.lastPathComponent == binaryName }) {
                try? fm.removeItem(atPath: dest)
                try fm.copyItem(at: binary, to: URL(fileURLWithPath: dest))
                try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest)
            } else {
                throw DependencyError.installFailed(dependency, "\(binaryName) not found in archive")
            }

        case .deno:
            let tmpDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: tmpDir) }

            let unzipResult = try runSync(
                executable: "/usr/bin/unzip",
                arguments: ["-oq", downloadedFile.path, "-d", tmpDir.path]
            )
            guard unzipResult == 0 else {
                throw DependencyError.installFailed(.deno, "Extraction failed")
            }

            let dest = "\(binDir)/deno"
            let binary = tmpDir.appendingPathComponent("deno")
            try? fm.removeItem(atPath: dest)
            try fm.copyItem(at: binary, to: URL(fileURLWithPath: dest))
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest)
        }
    }

    private func runSync(executable: String, arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    // MARK: - GitHub API

    struct GitHubAsset: Codable {
        let name: String
        let downloadURL: String

        enum CodingKeys: String, CodingKey {
            case name
            case downloadURL = "browser_download_url"
        }
    }

    struct GitHubRelease: Codable {
        let tagName: String
        let assets: [GitHubAsset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case assets
        }
    }

    func getLatestReleaseAssetURL(repo: String, assetName: String) async throws -> URL {
        let assets = try await getLatestReleaseAssets(repo: repo)
        guard let asset = assets.first(where: { $0.name == assetName }) else {
            throw DependencyError.downloadFailed(.ytDlp, "Asset '\(assetName)' not found")
        }
        guard let url = URL(string: asset.downloadURL) else {
            throw DependencyError.downloadFailed(.ytDlp, "Invalid download URL")
        }
        return url
    }

    func getLatestReleaseAssets(repo: String) async throws -> [GitHubAsset] {
        let apiURL = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DependencyError.downloadFailed(.ytDlp, "GitHub API error")
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        return release.assets
    }

    func downloadFile(from url: URL, to destination: URL) async throws {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DependencyError.downloadFailed(.ytDlp, "Download HTTP error")
        }
        try? FileManager.default.removeItem(at: destination)
        try data.write(to: destination)
    }
}

// MARK: - ダウンロード進捗デリゲート

final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    private let onProgress: @Sendable (Double, String) -> Void
    private let destination: URL
    private let continuation: CheckedContinuation<Void, Error>
    private var hasResumed = false

    init(
        onProgress: @escaping @Sendable (Double, String) -> Void,
        destination: URL,
        continuation: CheckedContinuation<Void, Error>
    ) {
        self.onProgress = onProgress
        self.destination = destination
        self.continuation = continuation
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let written = Self.formatBytes(totalBytesWritten)
        if totalBytesExpectedToWrite > 0 {
            let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            let total = Self.formatBytes(totalBytesExpectedToWrite)
            onProgress(percent, "\(written) / \(total)")
        } else {
            onProgress(-1, "\(written)")
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard !hasResumed else { return }
        hasResumed = true
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            continuation.resume()
        } catch {
            continuation.resume(throwing: error)
        }
        session.invalidateAndCancel()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard !hasResumed else { return }
        hasResumed = true
        if let error = error {
            continuation.resume(throwing: error)
        }
        session.invalidateAndCancel()
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1 {
            return String(format: "%.1f MB", mb)
        }
        let kb = Double(bytes) / 1024
        return String(format: "%.0f KB", kb)
    }
}

// ProcessInfo拡張でアーキテクチャ取得
extension ProcessInfo {
    var machineArchitecture: String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine
    }
}
