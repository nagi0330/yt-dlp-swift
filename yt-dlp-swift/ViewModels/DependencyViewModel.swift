import Foundation

@Observable
class DependencyViewModel {
    let manager = DependencyManager.shared
    var statuses: [DependencyStatus] = Dependency.allCases.map { DependencyStatus(dependency: $0) }
    var isSetupRequired = false
    var installProgress: String = ""
    var isInstalling = false
    var installError: String?

    var allInstalled: Bool {
        // ffprobeはffmpegと一緒にインストールされるので除外
        statuses.filter { $0.dependency != .ffprobe }.allSatisfy { $0.isInstalled }
    }

    // 全依存関係をチェック
    func checkAllDependencies() async {
        for i in statuses.indices {
            let dep = statuses[i].dependency
            let path = manager.resolveBinaryPath(for: dep)
            statuses[i].isInstalled = path != nil
            statuses[i].path = path

            if path != nil {
                statuses[i].version = await manager.getVersion(for: dep)
            }
        }

        isSetupRequired = !allInstalled
    }

    // 未インストールの依存関係をすべてインストール
    func installMissing() async {
        isInstalling = true
        installError = nil

        for i in statuses.indices {
            guard !statuses[i].isInstalled else { continue }

            let dep = statuses[i].dependency
            // ffprobeはffmpegのインストールに含まれる
            if dep == .ffprobe { continue }

            statuses[i].isUpdating = true

            do {
                switch dep {
                case .ytDlp:
                    try await manager.installYtDlp { [weak self] msg in
                        Task { @MainActor in
                            self?.installProgress = "\(dep.displayName): \(msg)"
                        }
                    }
                case .ffmpeg:
                    try await manager.installFFmpeg { [weak self] msg in
                        Task { @MainActor in
                            self?.installProgress = "\(dep.displayName): \(msg)"
                        }
                    }
                case .deno:
                    try await manager.installDeno { [weak self] msg in
                        Task { @MainActor in
                            self?.installProgress = "\(dep.displayName): \(msg)"
                        }
                    }
                case .ffprobe:
                    break
                }

                await MainActor.run {
                    statuses[i].isInstalled = true
                    statuses[i].isUpdating = false
                    statuses[i].path = manager.resolveBinaryPath(for: dep)
                }

                // バージョン取得
                statuses[i].version = await manager.getVersion(for: dep)

            } catch {
                await MainActor.run {
                    statuses[i].isUpdating = false
                    installError = error.localizedDescription
                }
            }
        }

        // ffprobeの状態も更新
        if let ffprobeIdx = statuses.firstIndex(where: { $0.dependency == .ffprobe }) {
            let path = manager.resolveBinaryPath(for: .ffprobe)
            statuses[ffprobeIdx].isInstalled = path != nil
            statuses[ffprobeIdx].path = path
            if path != nil {
                statuses[ffprobeIdx].version = await manager.getVersion(for: .ffprobe)
            }
        }

        isInstalling = false
        isSetupRequired = !allInstalled
        installProgress = ""
    }

    // 個別の依存関係を更新
    func update(_ dependency: Dependency) async {
        guard let idx = statuses.firstIndex(where: { $0.dependency == dependency }) else { return }

        statuses[idx].isUpdating = true
        installError = nil

        do {
            switch dependency {
            case .ytDlp:
                try await manager.installYtDlp { [weak self] msg in
                    Task { @MainActor in
                        self?.installProgress = msg
                    }
                }
            case .ffmpeg:
                try await manager.installFFmpeg { [weak self] msg in
                    Task { @MainActor in
                        self?.installProgress = msg
                    }
                }
            case .deno:
                try await manager.installDeno { [weak self] msg in
                    Task { @MainActor in
                        self?.installProgress = msg
                    }
                }
            case .ffprobe:
                // ffmpegと一緒に更新される
                try await manager.installFFmpeg { [weak self] msg in
                    Task { @MainActor in
                        self?.installProgress = msg
                    }
                }
            }

            statuses[idx].isUpdating = false
            statuses[idx].version = await manager.getVersion(for: dependency)
            installProgress = ""

        } catch {
            statuses[idx].isUpdating = false
            installError = error.localizedDescription
            installProgress = ""
        }
    }
}
