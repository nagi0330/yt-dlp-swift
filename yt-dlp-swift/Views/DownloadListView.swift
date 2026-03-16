import SwiftUI

struct DownloadListView: View {
    @Environment(DownloadViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text(L10n.downloads)
                    .font(.headline)
                Spacer()
                if viewModel.activeCount > 0 {
                    Text(L10n.activeCount(viewModel.activeCount))
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
                    Text(L10n.noDownloadTasks)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.tasks) { task in
                        DownloadRowView(
                            task: task,
                            onCancel: { viewModel.cancelTask(task) },
                            onResume: { viewModel.resumeTask(task) },
                            onRemove: { viewModel.removeTask(task) },
                            onRevealInFinder: { viewModel.revealInFinder(task) },
                            onOpenFile: { viewModel.openFile(task) }
                        )
                    }
                }
                .listStyle(.sidebar)

                Divider()

                // フッター
                if viewModel.completedCount > 0 {
                    HStack {
                        Spacer()
                        Button(L10n.clearCompleted) {
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
