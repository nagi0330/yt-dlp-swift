import Foundation

// Process実行ユーティリティ
enum ProcessRunner {
    struct ProcessResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    // コマンドを実行して結果を返す
    static func run(
        executableURL: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil
    ) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments
            if let env = environment {
                process.environment = env
            }
            if let dir = currentDirectoryURL {
                process.currentDirectoryURL = dir
            }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(returning: ProcessResult(
                    exitCode: proc.terminationStatus,
                    stdout: stdout,
                    stderr: stderr
                ))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // リアルタイム出力付きでプロセスを実行
    static func runWithLiveOutput(
        executableURL: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> (process: Process, exitCode: Int32) {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        if let env = environment {
            process.environment = env
        }
        if let dir = currentDirectoryURL {
            process.currentDirectoryURL = dir
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // readabilityHandlerでリアルタイム出力を取得
        let handler: @Sendable (FileHandle) -> Void = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let output = String(data: data, encoding: .utf8) {
                onOutput(output)
            }
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = handler
        stderrPipe.fileHandleForReading.readabilityHandler = handler

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                // ハンドラーを先にクリアしてからcontinuation
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                // 残りのデータを読み切る
                let remainStdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let remainStderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                if !remainStdout.isEmpty, let str = String(data: remainStdout, encoding: .utf8) {
                    onOutput(str)
                }
                if !remainStderr.isEmpty, let str = String(data: remainStderr, encoding: .utf8) {
                    onOutput(str)
                }

                continuation.resume(returning: (process: proc, exitCode: proc.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}
