import SwiftUI
import UserNotifications
import Sparkle

@main
struct YtDlpSwiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var dependencyViewModel = DependencyViewModel()
    @State private var mainViewModel = MainViewModel()
    @State private var downloadViewModel = DownloadViewModel()
    @State private var settingsViewModel = SettingsViewModel()

    // Sparkle アップデーター
    private let updaterController: SPUStandardUpdaterController

    // 言語変更時にView全体を再構築するためのキー
    @AppStorage("language") private var language = AppLanguage.system.rawValue
    @AppStorage("menuBarEnabled") private var menuBarEnabled = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(dependencyViewModel)
                .environment(mainViewModel)
                .environment(downloadViewModel)
                .environment(settingsViewModel)
                .id(language) // 言語変更時にView階層を再構築
                .task {
                    await dependencyViewModel.checkAllDependencies()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) {}

            // アプリメニューに「アップデートを確認」を追加
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }

        Settings {
            SettingsView(updater: updaterController.updater)
                .environment(settingsViewModel)
                .environment(dependencyViewModel)
                .id(language)
        }

        // メニューバー常駐
        MenuBarExtra(isInserted: $menuBarEnabled) {
            MenuBarView()
                .id(language)
        } label: {
            Label {
                Text("yt-dlp-swift")
            } icon: {
                Image(systemName: "arrow.down.circle")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

// メニューバーの「アップデートを確認」ボタン
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button(L10n.checkForUpdates) {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

// Sparkle のアップデート可能状態を監視する ViewModel
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // アプリがフォアグラウンドでも通知バナーを表示する
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
