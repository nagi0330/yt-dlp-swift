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
                    Label(L10n.generalTab, systemImage: "gear")
                }

            // 依存ライブラリ
            DependencySetupView()
                .tabItem {
                    Label(L10n.dependenciesTab, systemImage: "shippingbox")
                }
        }
        .frame(width: 550, height: 530)
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
        }
        .formStyle(.grouped)
        .onChange(of: viewModel.downloadDirectory) { viewModel.save() }
        .onChange(of: viewModel.defaultPreset) { viewModel.save() }
        .onChange(of: viewModel.maxConcurrentDownloads) { viewModel.save() }
        .onChange(of: viewModel.outputTemplate) { viewModel.save() }
        .onChange(of: viewModel.clipboardMonitoring) { viewModel.save() }
        .onChange(of: viewModel.extraArguments) { viewModel.save() }
        .onChange(of: viewModel.preferredContainer) { viewModel.save() }
        .onChange(of: viewModel.menuBarEnabled) { viewModel.save() }
        .onChange(of: viewModel.language) { viewModel.save() }
    }
}
