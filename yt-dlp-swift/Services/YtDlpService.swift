import Foundation

// yt-dlp CLIの呼び出しラッパー
enum YtDlpError: LocalizedError {
    case binaryNotFound
    case invalidURL
    case fetchFailed(String)
    case downloadFailed(String)
    case jsonParseFailed(String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound: return "yt-dlpが見つかりません。依存関係の設定を確認してください。"
        case .invalidURL: return "無効なURLです。"
        case .fetchFailed(let msg): return "動画情報の取得に失敗しました: \(msg)"
        case .downloadFailed(let msg): return "ダウンロードに失敗しました: \(msg)"
        case .jsonParseFailed(let msg): return "動画情報の解析に失敗しました: \(msg)"
        }
    }
}

class YtDlpService {
    static let shared = YtDlpService()
    private let dependencyManager = DependencyManager.shared

    private func ytDlpURL() throws -> URL {
        guard let url = dependencyManager.resolveBinaryPath(for: .ytDlp) else {
            throw YtDlpError.binaryNotFound
        }
        return url
    }

    // yt-dlpの環境変数 (denoのパスを追加)
    private func buildEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        // denoをPATHに追加
        let binDir = dependencyManager.binDirectory.path
        if let existingPath = env["PATH"] {
            env["PATH"] = "\(binDir):\(existingPath)"
        } else {
            env["PATH"] = binDir
        }
        return env
    }

    // 動画情報を取得
    func fetchVideoInfo(url: String) async throws -> VideoInfo {
        let binaryURL = try ytDlpURL()

        var args = ["--dump-json", "--no-download", "--no-warnings"]
        // 追加引数
        let extra = AppSettings.extraArguments.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extra.isEmpty {
            args.append(contentsOf: extra.components(separatedBy: " ").filter { !$0.isEmpty })
        }
        args.append(url)

        let result = try await ProcessRunner.run(
            executableURL: binaryURL,
            arguments: args,
            environment: buildEnvironment()
        )

        if result.exitCode != 0 {
            let errorMsg = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw YtDlpError.fetchFailed(errorMsg.isEmpty ? "不明なエラー (終了コード: \(result.exitCode))" : errorMsg)
        }

        guard let jsonData = result.stdout.data(using: .utf8) else {
            throw YtDlpError.jsonParseFailed("JSON出力が空です")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(VideoInfo.self, from: jsonData)
        } catch {
            throw YtDlpError.jsonParseFailed(error.localizedDescription)
        }
    }

    // ダウンロードを実行 (リアルタイム進捗あり)
    func download(
        task: DownloadTask,
        onProgress: @escaping @Sendable (OutputParser.ProgressInfo) -> Void,
        onOutput: @escaping @Sendable (String) -> Void,
        onDestination: @escaping @Sendable (String) -> Void
    ) async throws {
        let binaryURL = try ytDlpURL()

        var args: [String] = [
            "--newline",
            "--progress",
            "-f", task.formatSelector,
            "-o", task.outputDirectory.appendingPathComponent(task.outputTemplate).path,
        ]

        // コンテナ指定
        let container = AppSettings.preferredContainer
        if container != VideoContainer.mp4.rawValue {
            args.append(contentsOf: ["--merge-output-format", container])
        }

        // 追加引数
        let extra = AppSettings.extraArguments.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extra.isEmpty {
            args.append(contentsOf: extra.components(separatedBy: " ").filter { !$0.isEmpty })
        }

        args.append(task.url)

        let (process, exitCode) = try await ProcessRunner.runWithLiveOutput(
            executableURL: binaryURL,
            arguments: args,
            environment: buildEnvironment()
        ) { output in
            // 各行をパース
            let lines = output.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                onOutput(trimmed)

                if let progress = OutputParser.parseProgress(trimmed) {
                    onProgress(progress)
                }

                if let destination = OutputParser.parseDestination(trimmed) {
                    onDestination(destination)
                }
            }
        }

        // Process参照を保持
        task.process = process

        if exitCode != 0 {
            throw YtDlpError.downloadFailed("終了コード: \(exitCode)")
        }
    }

    // 対応サイト一覧を取得
    func listExtractors() async throws -> [String] {
        let binaryURL = try ytDlpURL()

        let result = try await ProcessRunner.run(
            executableURL: binaryURL,
            arguments: ["--list-extractors"],
            environment: buildEnvironment()
        )

        guard result.exitCode == 0 else {
            return []
        }

        return result.stdout
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
