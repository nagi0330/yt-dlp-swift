import Foundation

// Process実行ユーティリティ
actor ProcessRunner {
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

            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(returning: ProcessResult(
                    exitCode: process.terminationStatus,
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

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let output = String(data: data, encoding: .utf8) {
                onOutput(output)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: (process: proc, exitCode: proc.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}
