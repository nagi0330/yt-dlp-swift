import SwiftUI
import Sparkle

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(DependencyViewModel.self) private var dependencyVM
    let updater: SPUUpdater

    @ObservedObject private var checkForUpdatesVM: CheckForUpdatesViewModel

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesVM = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        @Bindable var vm = viewModel

        TabView {
            // 一般設定
            generalSettings
                .tabItem {
                    Label(L10n.generalTab, systemImage: "gear")
                }

            // 依存ライブラリ
            DependencySetupView()
                .tabItem {
                    Label(L10n.dependenciesTab, systemImage: "shippingbox")
                }
        }
        .frame(width: 550, height: 620)
    }

    private var generalSettings: some View {
        @Bindable var vm = viewModel

        return Form {
            Section(L10n.languageSection) {
                Picker(L10n.languagePicker, selection: $vm.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
            }

            Section(L10n.downloadDestination) {
                HStack {
                    Text(viewModel.downloadDirectory)
                        .truncationMode(.head)
                        .lineLimit(1)
                    Spacer()
                    Button(L10n.changeButton) {
                        viewModel.chooseDownloadDirectory()
                    }
                }
            }

            Section(L10n.defaultSettings) {
                Picker(L10n.defaultFormat, selection: $vm.defaultPreset) {
                    ForEach(DownloadPreset.allCases.filter { $0 != .custom }) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                }

                Picker(L10n.containerFormat, selection: $vm.preferredContainer) {
                    ForEach(VideoContainer.allCases) { container in
                        Text(container.displayName).tag(container.rawValue)
                    }
                }

                Picker(L10n.concurrentDownloads, selection: $vm.maxConcurrentDownloads) {
                    ForEach(1...5, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }

                Picker(L10n.playlistBehavior, selection: $vm.playlistBehavior) {
                    ForEach(PlaylistBehavior.allCases) { behavior in
                        Text(behavior.displayName).tag(behavior.rawValue)
                    }
                }
            }

            Section(L10n.fileNameTemplate) {
                Picker(L10n.preset, selection: $vm.outputTemplate) {
                    ForEach(AppSettings.outputTemplatePresets, id: \.template) { preset in
                        Text(preset.name).tag(preset.template)
                    }
                }
                TextField(L10n.customTemplate, text: $vm.outputTemplate)
                    .font(.system(.body, design: .monospaced))
            }

            Section(L10n.otherSettings) {
                Toggle(L10n.menuBarResident, isOn: $vm.menuBarEnabled)
                Toggle(L10n.clipboardMonitoring, isOn: $vm.clipboardMonitoring)

                VStack(alignment: .leading) {
                    Text(L10n.extraArgsLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(L10n.extraArgsPlaceholder, text: $vm.extraArguments)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section(L10n.appUpdateSection) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.appVersion)
                            .font(.body)
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(L10n.checkForUpdates) {
                        updater.checkForUpdates()
                    }
                    .disabled(!checkForUpdatesVM.canCheckForUpdates)
                }

                Toggle(L10n.autoCheckUpdates, isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))
            }

            Section(L10n.ytDlpPathSection) {
                Picker(L10n.ytDlpPathLabel, selection: $vm.ytDlpPath) {
                    ForEach(ytDlpPathOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }

                if vm.ytDlpPath == YtDlpPathOption.custom.rawValue {
                    HStack {
                        TextField(L10n.ytDlpPathCustomPlaceholder, text: $vm.ytDlpCustomPath)
                            .font(.system(.body, design: .monospaced))
                        Button(L10n.browseButton) {
                            chooseYtDlpBinary()
                        }
                    }
                }

                // 現在使用中のパスを表示
                if let resolvedPath = DependencyManager.shared.resolveBinaryPath(for: .ytDlp) {
                    Text(L10n.ytDlpCurrentPath(resolvedPath.path))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .onChange(of: viewModel.playlistBehavior) { viewModel.save() }
        .onChange(of: viewModel.menuBarEnabled) { viewModel.save() }
        .onChange(of: viewModel.language) { viewModel.save() }
        .onChange(of: viewModel.ytDlpPath) { viewModel.save() }
        .onChange(of: viewModel.ytDlpCustomPath) { viewModel.save() }
    }

    // 利用可能なyt-dlpパスのオプション（存在しないパスは非表示）
    private var ytDlpPathOptions: [(label: String, value: String)] {
        let manager = DependencyManager.shared
        var options: [(String, String)] = [
            (YtDlpPathOption.auto.displayName, YtDlpPathOption.auto.rawValue),
        ]
        // pip venv版が存在すれば表示
        let pipPath = manager.pipVenvDirectory.appendingPathComponent("bin/yt-dlp").path
        if FileManager.default.isExecutableFile(atPath: pipPath) {
            options.append((L10n.ytDlpPathPip, pipPath))
        }
        // 実在するプリセットパスのみ表示
        for preset in [YtDlpPathOption.usrLocalBin, .homebrewBin] {
            if FileManager.default.isExecutableFile(atPath: preset.rawValue) {
                options.append((preset.displayName, preset.rawValue))
            }
        }
        options.append((YtDlpPathOption.custom.displayName, YtDlpPathOption.custom.rawValue))
        return options
    }

    private func chooseYtDlpBinary() {
        let panel = NSOpenPanel()
        panel.title = L10n.ytDlpChooseBinary
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.ytDlpCustomPath = url.path
            viewModel.save()
        }
    }
}
