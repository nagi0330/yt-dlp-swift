import SwiftUI

struct FormatPickerView: View {
    @Environment(MainViewModel.self) private var viewModel

    private var videoPresets: [DownloadPreset] {
        DownloadPreset.allCases.filter { !$0.isAudioOnly && $0 != .custom }
    }

    private var audioPresets: [DownloadPreset] {
        DownloadPreset.allCases.filter { $0.isAudioOnly }
    }

    var body: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.downloadSettings)
                .font(.headline)

            // 利用可能な解像度の概要
            if let info = viewModel.videoInfo, let maxH = info.maxHeight {
                HStack(spacing: 4) {
                    Image(systemName: "film")
                        .foregroundStyle(.secondary)
                    Text(L10n.maxResolution(L10n.resolutionLabel(maxH)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // プリセット選択
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.qualityFormat)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.video)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    ForEach(videoPresets) { preset in
                        presetRow(preset)
                    }

                    Divider().padding(.vertical, 2)

                    Text(L10n.audioOnly)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    ForEach(audioPresets) { preset in
                        presetRow(preset)
                    }

                    Divider().padding(.vertical, 2)

                    presetRow(.custom)
                }
            }

            // カスタムフォーマット
            if viewModel.selectedPreset == .custom {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.customFormatLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(L10n.customFormatPlaceholder, text: $vm.customFormatString)
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
                    Label(L10n.startDownload, systemImage: "arrow.down.circle.fill")
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

    @ViewBuilder
    private func presetRow(_ preset: DownloadPreset) -> some View {
        let available = preset.isAvailable(for: viewModel.videoInfo)
        let isSelected = viewModel.selectedPreset == preset

        HStack(spacing: 6) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(available ? Color.accentColor : Color.gray.opacity(0.3))
                .font(.body)

            Text(preset.displayName)
                .foregroundStyle(available ? .primary : .tertiary)

            if !available {
                Text(L10n.unavailable)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if available {
                viewModel.selectedPreset = preset
            }
        }
    }
}
