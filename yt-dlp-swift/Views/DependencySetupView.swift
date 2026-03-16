import SwiftUI

struct DependencySetupView: View {
    @Environment(DependencyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                Text(L10n.dependencyManagement)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(L10n.dependencySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 依存ライブラリリスト
            VStack(spacing: 8) {
                ForEach(viewModel.statuses) { status in
                    DependencyRow(status: status, isInstalling: viewModel.isInstalling) {
                        Task { await viewModel.update(status.dependency) }
                    }
                }
            }
            .padding(.horizontal)

            // エラー表示
            if let error = viewModel.installError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            // プログレスバー
            if viewModel.isInstalling {
                VStack(spacing: 6) {
                    ProgressView(value: viewModel.installProgress)
                        .progressViewStyle(.linear)
                    HStack {
                        Text(viewModel.installStepDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !viewModel.downloadSizeInfo.isEmpty {
                            Text(viewModel.downloadSizeInfo)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(.horizontal)
            }

            // ログ表示エリア
            if !viewModel.logLines.isEmpty || viewModel.isInstalling {
                LogConsoleView(logLines: viewModel.logLines, isRunning: viewModel.isInstalling)
            }

            Spacer(minLength: 0)

            // アクションボタン
            HStack {
                if viewModel.allInstalled && !viewModel.isInstalling {
                    Button(L10n.close) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                } else {
                    Button(L10n.autoInstall) {
                        Task { await viewModel.installMissing() }
                    }
                    .disabled(viewModel.isInstalling || viewModel.allInstalled)
                    .keyboardShortcut(.defaultAction)

                    Button(L10n.skip) {
                        viewModel.isSetupRequired = false
                        dismiss()
                    }
                    .disabled(viewModel.isInstalling)
                    .keyboardShortcut(.cancelAction)
                }

                Spacer()

                Button {
                    Task { await viewModel.checkAllDependencies() }
                } label: {
                    Label(L10n.recheck, systemImage: "arrow.clockwise")
                }
                .controlSize(.small)
                .disabled(viewModel.isInstalling)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }
}

// ログコンソール
struct LogConsoleView: View {
    let logLines: [String]
    let isRunning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.log)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                if isRunning {
                    ProgressView()
                        .controlSize(.mini)
                    Text(L10n.running)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(logLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(logLineColor(line))
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 200)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal)
                .onChange(of: logLines.count) {
                    if let lastIndex = logLines.indices.last {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func logLineColor(_ line: String) -> Color {
        if line.contains(L10n.error) || line.contains("ERROR") || line.contains("エラー") {
            return .red
        }
        if line.contains(L10n.installComplete) || line.contains(L10n.installDone)
            || line.contains("インストール完了") || line.contains("完了しました") {
            return .green
        }
        return .primary
    }
}

struct DependencyRow: View {
    let status: DependencyStatus
    let isInstalling: Bool
    let onUpdate: () -> Void

    var body: some View {
        HStack {
            // ステータスアイコン
            if status.isUpdating {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: status.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(status.isInstalled ? .green : .red)
                    .frame(width: 20, height: 20)
            }

            // 依存ライブラリ情報
            VStack(alignment: .leading, spacing: 2) {
                Text(status.dependency.displayName)
                    .font(.body)

                if status.isCheckingVersion {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text(L10n.checkingVersion)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if let version = status.version {
                    HStack(spacing: 4) {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if status.isCheckingUpdate {
                            ProgressView()
                                .controlSize(.mini)
                            Text(L10n.checkingUpdate)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else if status.isLatest {
                            Text(L10n.upToDate)
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else if let latest = status.latestVersion {
                            Text(L10n.updateAvailable(latest))
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                } else if !status.isInstalled {
                    Text(L10n.notInstalled)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                if let path = status.path {
                    Text(path.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            // ボタン表示
            if !status.isUpdating && !isInstalling {
                if !status.isInstalled {
                    Button(L10n.install) {
                        onUpdate()
                    }
                    .controlSize(.small)
                } else if status.isCheckingVersion || status.isCheckingUpdate {
                    EmptyView()
                } else if status.isLatest {
                    EmptyView()
                } else if status.latestVersion != nil {
                    Button(L10n.update) {
                        onUpdate()
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
