import SwiftUI

struct MainView: View {
    @Environment(DependencyViewModel.self) private var dependencyVM
    @Environment(MainViewModel.self) private var mainVM
    @Environment(DownloadViewModel.self) private var downloadVM

    @State private var showSupportedSites = false

    var body: some View {
        NavigationSplitView {
            // サイドバー: ダウンロードキュー
            DownloadListView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // メイン: URL入力 + 動画情報 + フォーマット選択
            VStack(spacing: 0) {
                URLInputView()
                    .padding()

                Divider()

                if mainVM.isFetching {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView(L10n.fetchingVideoInfo)
                        Button(L10n.cancel) {
                            mainVM.cancelFetch()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding()
                    Spacer()
                } else if let videoInfo = mainVM.videoInfo {
                    ScrollView {
                        VStack(spacing: 16) {
                            VideoInfoView(videoInfo: videoInfo) {
                                mainVM.startDownload()
                            }
                            FormatPickerView()
                        }
                        .padding()
                    }
                } else if let error = mainVM.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(L10n.enterURLPlaceholder)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SettingsLink {
                    Label(L10n.settingsToolbar, systemImage: "gearshape.2")
                }
                .help(L10n.settings)
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showSupportedSites = true
                } label: {
                    Label(L10n.supportedSites, systemImage: "globe")
                }
                .help(L10n.supportedSitesList)
            }
        }
        .sheet(isPresented: $showSupportedSites) {
            SupportedSitesView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .sheet(isPresented: .init(
            get: { dependencyVM.isSetupRequired },
            set: { _ in }
        )) {
            DependencySetupView()
                .frame(minWidth: 500, minHeight: 400)
                .interactiveDismissDisabled()
        }
        .alert(L10n.playlistDetectedTitle, isPresented: playlistAlertBinding) {
            Button(L10n.downloadSingleVideo) {
                mainVM.confirmPlaylistChoice(downloadPlaylist: false)
            }
            Button(L10n.downloadEntirePlaylist) {
                mainVM.confirmPlaylistChoice(downloadPlaylist: true)
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.playlistDetectedMessage)
        }
    }

    private var playlistAlertBinding: Binding<Bool> {
        @Bindable var vm = mainVM
        return $vm.showPlaylistAlert
    }
}
