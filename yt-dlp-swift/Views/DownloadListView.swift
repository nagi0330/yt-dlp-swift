import SwiftUI

struct DownloadListView: View {
    @Environment(DownloadViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("ダウンロード")
                    .font(.headline)
                Spacer()
                if viewModel.activeCount > 0 {
                    Text("\(viewModel.activeCount)件 実行中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if viewModel.tasks.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("ダウンロードタスクなし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.tasks) { task in
                        DownloadRowView(task: task)
                            .contextMenu {
                                if task.status == .completed {
                                    Button("Finderで表示") {
                                        viewModel.revealInFinder(task)
                                    }
                                }
                                if task.status == .downloading || task.status == .processing {
                                    Button("キャンセル") {
                                        viewModel.cancelTask(task)
                                    }
                                }
                                Divider()
                                Button("削除", role: .destructive) {
                                    viewModel.removeTask(task)
                                }
                            }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                // フッター
                if viewModel.completedCount > 0 {
                    HStack {
                        Spacer()
                        Button("完了済みをクリア") {
                            viewModel.clearCompleted()
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}
