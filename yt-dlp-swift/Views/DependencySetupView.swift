import SwiftUI

struct DependencySetupView: View {
    @Environment(DependencyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                Text("依存関係の管理")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("yt-dlp-swift は以下のツールを使用します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 依存関係リスト
            VStack(spacing: 8) {
                ForEach(viewModel.statuses) { status in
                    DependencyRow(status: status) {
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

            // 進捗表示
            if !viewModel.installProgress.isEmpty {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text(viewModel.installProgress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // アクションボタン
            HStack {
                if viewModel.allInstalled {
                    Button("閉じる") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                } else {
                    Button("自動インストール") {
                        Task { await viewModel.installMissing() }
                    }
                    .disabled(viewModel.isInstalling)
                    .keyboardShortcut(.defaultAction)

                    Button("スキップ") {
                        viewModel.isSetupRequired = false
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(.bottom)
        }
        .padding()
    }
}

struct DependencyRow: View {
    let status: DependencyStatus
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

            // 依存関係情報
            VStack(alignment: .leading, spacing: 2) {
                Text(status.dependency.displayName)
                    .font(.body)

                if let version = status.version {
                    Text("v\(version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if !status.isInstalled {
                    Text("未インストール")
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

            // 更新ボタン
            if status.isInstalled && !status.isUpdating {
                Button("更新") {
                    onUpdate()
                }
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
