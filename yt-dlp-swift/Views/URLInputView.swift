import SwiftUI

struct URLInputView: View {
    @Environment(MainViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                TextField("動画のURLを入力...", text: $vm.urlText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await viewModel.fetchVideoInfo() }
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

            Button {
                viewModel.pasteFromClipboard()
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .help("クリップボードから貼り付け")

            Button {
                Task { await viewModel.fetchVideoInfo() }
            } label: {
                Label("取得", systemImage: "magnifyingglass")
            }
            .disabled(viewModel.urlText.isEmpty || viewModel.isFetching)
            .keyboardShortcut(.return, modifiers: .command)
        }
    }
}
