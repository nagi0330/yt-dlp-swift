import SwiftUI

struct MenuBarView: View {
    @State private var urlText = ""
    @State private var isDownloading = false
    private let downloadManager = DownloadManager.shared

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダー
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.tint)
                Text("yt-dlp-swift")
                    .font(.headline)
                Spacer()
                // アクティブDL数
                if activeCount > 0 {
                    Label("\(activeCount)", systemImage: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // URL入力
            HStack(spacing: 8) {
                TextField(L10n.menuBarURLPlaceholder, text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { startQuickDownload() }

                Button {
                    pasteFromClipboard()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                .help(L10n.menuBarPaste)
            }

            // ダウンロードボタン
            Button {
                startQuickDownload()
            } label: {
                HStack {
                    if isDownloading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(L10n.menuBarDownload)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDownloading)

            Divider()

            // アクティブなDLタスク一覧（最新5件）
            if !recentTasks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.menuBarRecentDownloads)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(recentTasks) { task in
                        MenuBarTaskRow(task: task)
                    }
                }
            }

            Divider()

            // メインウィンドウを開く / 終了
            HStack {
                Button(L10n.menuBarOpenMainWindow) {
                    openMainWindow()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(L10n.menuBarQuit) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(12)
        .frame(width: 320)
    }

    private var activeCount: Int {
        downloadManager.tasks.filter { $0.status == .downloading || $0.status == .processing }.count
    }

    private var recentTasks: [DownloadTask] {
        Array(downloadManager.tasks.prefix(5))
    }

    private func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" {
                urlText = trimmed
            }
        }
    }

    private func startQuickDownload() {
        let url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty,
              let parsed = URL(string: url),
              parsed.scheme == "http" || parsed.scheme == "https" else { return }

        isDownloading = true

        let preset = DownloadPreset.allCases.first { $0.rawValue == AppSettings.defaultPreset } ?? .bestVideo

        downloadManager.addTask(
            url: url,
            title: url,
            formatSelector: preset.formatString,
            container: AppSettings.preferredContainer,
            postProcessorArgs: preset.postProcessorArgs
        )

        urlText = ""
        isDownloading = false
    }

    private func openMainWindow() {
        // メインウィンドウをアクティブにする
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.title != "" && !($0 is NSPanel) }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // ウィンドウが閉じられていた場合は新しいウィンドウを開く
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

struct MenuBarTaskRow: View {
    let task: DownloadTask

    var body: some View {
        HStack(spacing: 6) {
            // ステータスアイコン
            Group {
                switch task.status {
                case .downloading, .processing:
                    ProgressView(value: task.progress)
                        .progressViewStyle(.circular)
                        .controlSize(.mini)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                case .cancelled:
                    Image(systemName: "slash.circle")
                        .foregroundStyle(.secondary)
                case .waiting:
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                case .paused:
                    Image(systemName: "pause.circle")
                        .foregroundStyle(.secondary)
                case .recording:
                    Image(systemName: "record.circle")
                        .foregroundStyle(.red)
                }
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if task.status == .downloading || task.status == .processing {
                    HStack(spacing: 4) {
                        Text("\(Int(task.progress * 100))%")
                        if !task.speed.isEmpty {
                            Text("·")
                            Text(task.speed)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}
