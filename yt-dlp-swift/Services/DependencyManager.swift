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
        case .ytDlp: return "yt-dlp (動画ダウンローダー)"
        case .ffmpeg: return "FFmpeg (動画変換エンジン)"
        case .ffprobe: return "FFprobe (メディア解析)"
        case .deno: return "Deno (JavaScriptランタイム)"
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
        case .notInstalled(let dep): return "\(dep.displayName) がインストールされていません"
        case .downloadFailed(let dep, let msg): return "\(dep.displayName) のダウンロードに失敗しました: \(msg)"
        case .installFailed(let dep, let msg): return "\(dep.displayName) のインストールに失敗しました: \(msg)"
        }
    }
}

struct DependencyStatus: Identifiable {
    var id: String { dependency.id }
    let dependency: Dependency
    var isInstalled: Bool = false
    var version: String?
    var path: URL?
    var isUpdating: Bool = false
}

@Observable
class DependencyManager {
    static let shared = DependencyManager()

    let binDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        binDirectory = appSupport.appendingPathComponent("yt-dlp-swift/bin", isDirectory: true)
    }

    // binディレクトリを作成
    func ensureBinDirectory() throws {
        try FileManager.default.createDirectory(at: binDirectory, withIntermediateDirectories: true)
    }

    // 依存バイナリのパスを解決 (アプリ管理 → システム の優先順)
    func resolveBinaryPath(for dependency: Dependency) -> URL? {
        // アプリ管理のバイナリ
        let appBinary = binDirectory.appendingPathComponent(dependency.binaryName)
        if FileManager.default.isExecutableFile(atPath: appBinary.path) {
            return appBinary
        }

        // システムにインストール済みのバイナリを検索
        let systemPaths = [
            "/usr/local/bin/\(dependency.binaryName)",
            "/opt/homebrew/bin/\(dependency.binaryName)",
            "/usr/bin/\(dependency.binaryName)",
        ]

        for path in systemPaths {
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
                // ffmpegは1行目からバージョンを抽出
                if dependency == .ffmpeg || dependency == .ffprobe {
                    if let firstLine = output.components(separatedBy: "\n").first {
                        return firstLine
                    }
                }
                // denoは複数行出力するので最初の行
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

    // yt-dlpをGitHub Releasesからインストール
    func installYtDlp(onProgress: @escaping @Sendable (String) -> Void) async throws {
        try ensureBinDirectory()

        onProgress("最新バージョンを確認中...")
        let downloadURL = try await getLatestReleaseAssetURL(
            repo: "yt-dlp/yt-dlp",
            assetName: "yt-dlp_macos"
        )

        onProgress("ダウンロード中...")
        let destinationPath = binDirectory.appendingPathComponent("yt-dlp")
        try await downloadFile(from: downloadURL, to: destinationPath)

        // 実行権限を付与
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: destinationPath.path
        )
        onProgress("インストール完了")
    }

    // ffmpegをインストール
    func installFFmpeg(onProgress: @escaping @Sendable (String) -> Void) async throws {
        try ensureBinDirectory()

        onProgress("最新バージョンを確認中...")

        // アーキテクチャ判定
        let arch = ProcessInfo.processInfo.machineArchitecture
        let assetPattern = arch == "arm64" ? "macos64" : "macos64"

        let assets = try await getLatestReleaseAssets(repo: "yt-dlp/FFmpeg-Builds")
        guard let asset = assets.first(where: { $0.name.contains(assetPattern) && $0.name.hasSuffix(".tar.xz") }) else {
            throw DependencyError.downloadFailed(.ffmpeg, "対応するバイナリが見つかりません")
        }

        onProgress("ダウンロード中...")
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let archivePath = tempDir.appendingPathComponent("ffmpeg.tar.xz")
        try await downloadFile(from: URL(string: asset.downloadURL)!, to: archivePath)

        onProgress("展開中...")
        // tar.xzを展開
        let tarResult = try await ProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/tar"),
            arguments: ["xf", archivePath.path, "-C", tempDir.path]
        )

        guard tarResult.exitCode == 0 else {
            throw DependencyError.installFailed(.ffmpeg, "アーカイブの展開に失敗しました")
        }

        // ffmpegとffprobeバイナリを探してコピー
        onProgress("インストール中...")
        let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            let fileName = fileURL.lastPathComponent
            if fileName == "ffmpeg" || fileName == "ffprobe" {
                let dest = binDirectory.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: fileURL, to: dest)
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: dest.path
                )
            }
        }
        onProgress("インストール完了")
    }

    // Denoをインストール
    func installDeno(onProgress: @escaping @Sendable (String) -> Void) async throws {
        try ensureBinDirectory()

        onProgress("最新バージョンを確認中...")

        let arch = ProcessInfo.processInfo.machineArchitecture
        let assetName = arch == "arm64" ? "deno-aarch64-apple-darwin.zip" : "deno-x86_64-apple-darwin.zip"

        let downloadURL = try await getLatestReleaseAssetURL(
            repo: "denoland/deno",
            assetName: assetName
        )

        onProgress("ダウンロード中...")
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let zipPath = tempDir.appendingPathComponent("deno.zip")
        try await downloadFile(from: downloadURL, to: zipPath)

        onProgress("展開中...")
        let unzipResult = try await ProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/unzip"),
            arguments: ["-o", zipPath.path, "-d", tempDir.path]
        )

        guard unzipResult.exitCode == 0 else {
            throw DependencyError.installFailed(.deno, "ZIPの展開に失敗しました")
        }

        let denoBinary = tempDir.appendingPathComponent("deno")
        let dest = binDirectory.appendingPathComponent("deno")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.copyItem(at: denoBinary, to: dest)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: dest.path
        )
        onProgress("インストール完了")
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
            throw DependencyError.downloadFailed(.ytDlp, "アセット '\(assetName)' が見つかりません")
        }
        guard let url = URL(string: asset.downloadURL) else {
            throw DependencyError.downloadFailed(.ytDlp, "無効なダウンロードURL")
        }
        return url
    }

    func getLatestReleaseAssets(repo: String) async throws -> [GitHubAsset] {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DependencyError.downloadFailed(.ytDlp, "GitHub APIエラー")
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        return release.assets
    }

    func downloadFile(from url: URL, to destination: URL) async throws {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DependencyError.downloadFailed(.ytDlp, "ダウンロードHTTPエラー")
        }
        try? FileManager.default.removeItem(at: destination)
        try data.write(to: destination)
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
