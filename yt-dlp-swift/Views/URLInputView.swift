import SwiftUI

struct URLInputView: View {
    @Environment(MainViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                    TextField(L10n.urlInputPlaceholder, text: $vm.urlText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .onSubmit {
                            if !viewModel.isBulkMode {
                                Task { await viewModel.fetchVideoInfo() }
                            }
                        }

                    if !viewModel.urlText.isEmpty {
                        Button {
                            viewModel.urlText = ""
                            viewModel.videoInfo = nil
                            viewModel.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

                if viewModel.isBulkMode {
                    Button {
                        viewModel.startBulkDownload()
                    } label: {
                        Label(L10n.bulkDownload(viewModel.bulkURLs.count), systemImage: "arrow.down.circle.fill")
                    }
                    .disabled(viewModel.isFetching)
                    .keyboardShortcut(.return, modifiers: .command)
                } else {
                    Button {
                        Task { await viewModel.fetchVideoInfo() }
                    } label: {
                        Label(L10n.fetch, systemImage: "magnifyingglass")
                    }
                    .disabled(viewModel.urlText.isEmpty || viewModel.isFetching)
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }

            // 一括モード時の説明
            if viewModel.isBulkMode {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text(L10n.bulkURLDetected(viewModel.bulkURLs.count))
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
