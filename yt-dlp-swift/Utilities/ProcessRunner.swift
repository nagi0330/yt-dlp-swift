import Foundation

// Process実行ユーティリティ
enum ProcessRunner {
    struct ProcessResult: Sendable {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    // コマンドを実行して結果を返す
    // 全処理をバックグラウンドで実行し、MainActorをブロックしない
    static func run(
        executableURL: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil
    ) async throws -> ProcessResult {
        let execURL = executableURL
        let args = arguments
        let env = environment
        let dirURL = currentDirectoryURL

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = execURL
                process.arguments = args
                if let env = env {
                    process.environment = env
                }
                if let dir = dirURL {
                    process.currentDirectoryURL = dir
                }

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // stdout/stderrを別スレッドで並行読み取り（パイプバッファのデッドロック防止）
                var stdoutData = Data()
                var stderrData = Data()
                let group = DispatchGroup()

                group.enter()
                DispatchQueue.global().async {
                    stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    group.leave()
                }

                group.enter()
                DispatchQueue.global().async {
                    stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    group.leave()
                }

                group.wait()
                process.waitUntilExit()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(returning: ProcessResult(
                    exitCode: process.terminationStatus,
                    stdout: stdout,
                    stderr: stderr
                ))
            }
        }
    }

    // リアルタイム出力付きでプロセスを実行
    static func runWithLiveOutput(
        executableURL: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        onOutput: @escaping @Sendable (String) -> Void,
        onProcessStarted: (@Sendable (Process) -> Void)? = nil
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
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

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
                onProcessStarted?(process)
            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}
