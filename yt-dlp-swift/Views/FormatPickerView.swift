import SwiftUI

struct FormatPickerView: View {
    @Environment(MainViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .leading, spacing: 12) {
            Text("ダウンロード設定")
                .font(.headline)

            // プリセット選択
            VStack(alignment: .leading, spacing: 8) {
                Text("画質・フォーマット")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("プリセット", selection: $vm.selectedPreset) {
                    Section("動画") {
                        ForEach(DownloadPreset.allCases.filter { !$0.isAudioOnly && $0 != .custom }) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    Section("音声のみ") {
                        ForEach(DownloadPreset.allCases.filter { $0.isAudioOnly }) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    Section {
                        Text(DownloadPreset.custom.displayName).tag(DownloadPreset.custom)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            // カスタムフォーマット
            if viewModel.selectedPreset == .custom {
                VStack(alignment: .leading, spacing: 4) {
                    Text("カスタムフォーマット文字列 (-f オプション)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("例: bestvideo[height<=1080]+bestaudio", text: $vm.customFormatString)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Divider()

            // ダウンロードボタン
            HStack {
                Spacer()
                Button {
                    viewModel.startDownload()
                } label: {
                    Label("ダウンロード開始", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                }
                .controlSize(.large)
                .keyboardShortcut("d", modifiers: .command)
                .disabled(viewModel.videoInfo == nil)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
