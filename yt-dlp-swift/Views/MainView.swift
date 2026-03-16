import SwiftUI

struct MainView: View {
    @Environment(DependencyViewModel.self) private var dependencyVM
    @Environment(MainViewModel.self) private var mainVM
    @Environment(DownloadViewModel.self) private var downloadVM

    @State private var showDependencySetup = false
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
                    ProgressView("動画情報を取得中...")
                        .padding()
                    Spacer()
                } else if let videoInfo = mainVM.videoInfo {
                    ScrollView {
                        VStack(spacing: 16) {
                            VideoInfoView(videoInfo: videoInfo)
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
                        Text("URLを入力して動画情報を取得してください")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showDependencySetup = true
                } label: {
                    Label("依存関係", systemImage: "gearshape.2")
                }
                .help("依存関係の管理")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showSupportedSites = true
                } label: {
                    Label("対応サイト", systemImage: "globe")
                }
                .help("対応サイト一覧")
            }
        }
        .sheet(isPresented: $showDependencySetup) {
            DependencySetupView()
                .frame(minWidth: 500, minHeight: 400)
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
    }
}
