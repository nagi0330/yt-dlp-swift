import Foundation

@MainActor
@Observable
class DependencyViewModel {
    let manager = DependencyManager.shared
    var statuses: [DependencyStatus] = Dependency.allCases.map { DependencyStatus(dependency: $0) }
    var isSetupRequired = false
    var isInstalling = false
    var installError: String?
    var logLines: [String] = []
    var installProgress: Double = 0
    var installStepDescription: String = ""
    var downloadSizeInfo: String = ""

    var allInstalled: Bool {
        statuses.filter { $0.dependency != .ffprobe }.allSatisfy { $0.isInstalled }
    }

    // 全依存ライブラリをチェック
    func checkAllDependencies() async {
        // まずインストール状態を即座に反映（ファイル存在チェックのみ）
        for i in statuses.indices {
            let dep = statuses[i].dependency
            let path = manager.resolveBinaryPath(for: dep)
            statuses[i].isInstalled = path != nil
            statuses[i].path = path
            if path != nil {
                statuses[i].isCheckingVersion = true
                statuses[i].isCheckingUpdate = true
            }
        }
        isSetupRequired = !allInstalled

        // バージョン取得を並列実行
        await withTaskGroup(of: (Int, String?).self) { group in
            for i in statuses.indices where statuses[i].isInstalled {
                let dep = statuses[i].dependency
                group.addTask {
                    let version = await self.manager.getVersion(for: dep)
                    return (i, version)
                }
            }
            for await (index, version) in group {
                statuses[index].version = version
                statuses[index].isCheckingVersion = false
            }
        }

        // 最新バージョンをバックグラウンドで取得
        await checkLatestVersions()
    }

    // GitHub APIで最新バージョンを確認（並列）
    func checkLatestVersions() async {
        let targets = statuses.indices.filter {
            statuses[$0].isInstalled && statuses[$0].dependency != .ffprobe
        }

        for i in targets {
            statuses[i].isCheckingUpdate = true
        }

        await withTaskGroup(of: (Int, String?).self) { group in
            for i in targets {
                let dep = statuses[i].dependency
                group.addTask {
                    let latest = await self.manager.getLatestVersionTag(for: dep)
                    return (i, latest)
                }
            }
            for await (index, latest) in group {
                statuses[index].latestVersion = latest
                statuses[index].isCheckingUpdate = false

                if statuses[index].dependency == .ffmpeg,
                   let fpIdx = statuses.firstIndex(where: { $0.dependency == .ffprobe }) {
                    statuses[fpIdx].latestVersion = latest
                }
            }
        }
    }

    // 未インストールの依存ライブラリを一括インストール
    func installMissing() async {
        let missingDeps = statuses
            .filter { !$0.isInstalled && $0.dependency != .ffprobe }
            .map { $0.dependency }

        guard !missingDeps.isEmpty else { return }
        await installDependencies(missingDeps)
    }

    // 個別の依存ライブラリを更新
    func update(_ dependency: Dependency) async {
        await installDependencies([dependency])
    }

    // ログメッセージは英語ベース（技術ログなので全言語共通）
    private func installDependencies(_ dependencies: [Dependency]) async {
        isInstalling = true
        installError = nil
        logLines = []
        installProgress = 0
        installStepDescription = L10n.running
        downloadSizeInfo = ""

        // ffmpegの場合はffprobeもセットで更新
        var allDeps: [Dependency] = []
        for dep in dependencies {
            allDeps.append(dep)
            if dep == .ffmpeg && !dependencies.contains(.ffprobe) {
                allDeps.append(.ffprobe)
            }
        }

        for dep in allDeps {
            if let idx = statuses.firstIndex(where: { $0.dependency == dep }) {
                statuses[idx].isUpdating = true
            }
        }

        let totalCount = allDeps.count
        var completed = 0

        for dep in allDeps {
            let stepBase = Double(completed) / Double(totalCount)
            let stepSize = 1.0 / Double(totalCount)

            do {
                // URL解決
                installStepDescription = "\(dep.binaryName) — URL..."
                installProgress = stepBase
                appendLog("[\(dep.binaryName)] Resolving download URL...")

                let downloadURL = try await manager.resolveDownloadURL(for: dep)
                appendLog("[\(dep.binaryName)] URL resolved")

                // ダウンロード（進捗付き）
                let tmpFile = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(dep.binaryName)-\(UUID().uuidString)")

                installStepDescription = "\(dep.binaryName) — \(L10n.statusDownloading)..."
                appendLog("[\(dep.binaryName)] Downloading...")

                try await manager.downloadWithProgress(
                    from: downloadURL,
                    to: tmpFile,
                    onProgress: { [weak self] percent, sizeInfo in
                        Task { @MainActor [weak self] in
                            if percent >= 0 {
                                self?.installProgress = stepBase + (percent * stepSize * 0.8)
                            }
                            self?.downloadSizeInfo = sizeInfo
                        }
                    }
                )

                appendLog("[\(dep.binaryName)] Download complete")

                // インストール（展開・コピー）
                installStepDescription = "\(dep.binaryName) — \(L10n.install)..."
                installProgress = stepBase + stepSize * 0.8

                try manager.installDownloaded(dependency: dep, downloadedFile: tmpFile)
                try? FileManager.default.removeItem(at: tmpFile)

                completed += 1
                installProgress = Double(completed) / Double(totalCount)
                appendLog("[\(dep.binaryName)] \(L10n.installComplete)")

            } catch {
                appendLog("[\(dep.binaryName)] \(L10n.error): \(error.localizedDescription)")
                installError = error.localizedDescription
                break
            }
        }

        if installError == nil {
            installStepDescription = L10n.installDone
            installProgress = 1.0
            appendLog(L10n.installComplete)
        }

        downloadSizeInfo = ""
        resetUpdatingFlags()
        isInstalling = false

        // バックグラウンドでバージョン再チェック（UIはブロックしない）
        await checkAllDependencies()
    }

    private func appendLog(_ message: String) {
        logLines.append(message)
    }

    private func resetUpdatingFlags() {
        for i in statuses.indices {
            statuses[i].isUpdating = false
        }
    }
}
