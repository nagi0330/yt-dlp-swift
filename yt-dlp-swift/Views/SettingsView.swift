import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(DependencyViewModel.self) private var dependencyVM

    var body: some View {
        @Bindable var vm = viewModel

        TabView {
            // 一般設定
            generalSettings
                .tabItem {
                    Label("一般", systemImage: "gear")
                }

            // 依存関係
            DependencySetupView()
                .tabItem {
                    Label("依存関係", systemImage: "shippingbox")
                }
        }
        .frame(width: 550, height: 420)
    }

    private var generalSettings: some View {
        @Bindable var vm = viewModel

        return Form {
            Section("ダウンロード先") {
                HStack {
                    Text(viewModel.downloadDirectory)
                        .truncationMode(.head)
                        .lineLimit(1)
                    Spacer()
                    Button("変更...") {
                        viewModel.chooseDownloadDirectory()
                    }
                }
            }

            Section("デフォルト設定") {
                Picker("デフォルトフォーマット", selection: $vm.defaultPreset) {
                    ForEach(DownloadPreset.allCases.filter { $0 != .custom }) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                }

                Picker("コンテナ形式", selection: $vm.preferredContainer) {
                    ForEach(VideoContainer.allCases) { container in
                        Text(container.displayName).tag(container.rawValue)
                    }
                }

                Picker("並列ダウンロード数", selection: $vm.maxConcurrentDownloads) {
                    ForEach(1...5, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
            }

            Section("ファイル名テンプレート") {
                Picker("プリセット", selection: $vm.outputTemplate) {
                    ForEach(AppSettings.outputTemplatePresets, id: \.template) { preset in
                        Text(preset.name).tag(preset.template)
                    }
                }
                TextField("カスタムテンプレート", text: $vm.outputTemplate)
                    .font(.system(.body, design: .monospaced))
            }

            Section("その他") {
                Toggle("クリップボード監視", isOn: $vm.clipboardMonitoring)

                VStack(alignment: .leading) {
                    Text("yt-dlp 追加引数 (上級者向け)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("例: --cookies-from-browser safari", text: $vm.extraArguments)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: viewModel.downloadDirectory) { viewModel.save() }
        .onChange(of: viewModel.defaultPreset) { viewModel.save() }
        .onChange(of: viewModel.maxConcurrentDownloads) { viewModel.save() }
        .onChange(of: viewModel.outputTemplate) { viewModel.save() }
        .onChange(of: viewModel.clipboardMonitoring) { viewModel.save() }
        .onChange(of: viewModel.extraArguments) { viewModel.save() }
        .onChange(of: viewModel.preferredContainer) { viewModel.save() }
    }
}
