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
        case .binaryNotFound: return L10n.ytDlpNotFound
        case .invalidURL: return L10n.invalidURL
        case .fetchFailed(let msg): return L10n.fetchFailed(msg)
        case .downloadFailed(let msg): return L10n.downloadFailed(msg)
        case .jsonParseFailed(let msg): return L10n.jsonParseFailed(msg)
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

    private let cookieManager = CookieManager.shared

    // cookieファイルが存在する場合、--cookies 引数を追加
    private func appendCookieArgs(to args: inout [String]) {
        let mergedPath = cookieManager.mergedCookieFilePath
        if FileManager.default.fileExists(atPath: mergedPath.path) {
            args.append(contentsOf: ["--cookies", mergedPath.path])
        }
    }

    // yt-dlpの環境変数 (各ツールのパスを確保)
    private func buildEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        // 全検索パスをPATHに追加 (依存ツールがどこにあっても見つかるように)
        let extraDirs = dependencyManager.searchPaths.joined(separator: ":")
        if let existingPath = env["PATH"] {
            env["PATH"] = "\(extraDirs):\(existingPath)"
        } else {
            env["PATH"] = extraDirs
        }
        return env
    }

    // YouTube URLかどうかを判定
    private func isYouTubeURL(_ url: String) -> Bool {
        url.contains("youtube.com") || url.contains("youtu.be") || url.contains("music.youtube.com")
    }

    // NOTE: YouTube高速化（player_client制限）は画質低下を引き起こすため無効化
    // yt-dlpのデフォルト（複数クライアント問い合わせ）を使用する

    // 動画情報を取得
    func fetchVideoInfo(url: String) async throws -> VideoInfo {
        let binaryURL = try ytDlpURL()

        var args = [
            "--dump-json",
            "--no-download",
            "--no-warnings",
            "--no-check-formats",   // フォーマットURLの有効性チェックをスキップ
            "--no-playlist",        // プレイリストは処理しない（単一動画のみ）
            "--socket-timeout", "15",
        ]
        // 情報取得時はYouTube最適化を使わない（全フォーマット情報が必要）
        // Cookie
        appendCookieArgs(to: &args)
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
            throw YtDlpError.fetchFailed(errorMsg.isEmpty ? L10n.unknownError(result.exitCode) : errorMsg)
        }

        guard let jsonData = result.stdout.data(using: .utf8) else {
            throw YtDlpError.jsonParseFailed(L10n.emptyJSON)
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
            task.downloadPlaylist ? "--yes-playlist" : "--no-playlist",
            "-f", task.formatSelector,
            "-o", task.outputDirectory.appendingPathComponent(task.outputTemplate).path,
        ]

        // ライブ録画オプション
        if task.isLiveRecording {
            if task.liveFromStart {
                args.append("--live-from-start")
            }
            // ライブ配信が終了するまで待機
            args.append("--wait-for-video")
            args.append("5-30")
        }

        // 音声抽出の後処理引数
        if !task.postProcessorArgs.isEmpty {
            args.append(contentsOf: task.postProcessorArgs)
        }

        // Cookie
        appendCookieArgs(to: &args)

        // コンテナ指定 (映像DL時のみ、音声抽出時は不要)
        if task.postProcessorArgs.isEmpty {
            let container = task.container.isEmpty ? AppSettings.preferredContainer : task.container
            args.append(contentsOf: ["--merge-output-format", container])

            // mp4コンテナの場合、QuickTime互換コーデック (H.264+AAC) を優先
            // VP9/Opus等はmp4に入れてもQuickTimeで再生できないため
            if container == "mp4" {
                args.append(contentsOf: ["-S", "vcodec:h264,acodec:aac"])
            }
        }

        // メタデータ・サムネイル埋め込み
        args.append("--embed-metadata")
        args.append("--embed-thumbnail")

        // 追加引数
        let extra = AppSettings.extraArguments.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extra.isEmpty {
            args.append(contentsOf: extra.components(separatedBy: " ").filter { !$0.isEmpty })
        }

        args.append(task.url)

        let (_, exitCode) = try await ProcessRunner.runWithLiveOutput(
            executableURL: binaryURL,
            arguments: args,
            environment: buildEnvironment(),
            onOutput: { output in
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
            },
            onProcessStarted: { process in
                // プロセス開始直後にtaskに設定（キャンセル可能にする）
                Task { @MainActor in
                    task.process = process
                }
            }
        )

        if exitCode != 0 {
            throw YtDlpError.downloadFailed(L10n.exitCodeError(exitCode))
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
