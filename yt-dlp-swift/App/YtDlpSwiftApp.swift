import SwiftUI
import UserNotifications

@main
struct YtDlpSwiftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var dependencyViewModel = DependencyViewModel()
    @State private var mainViewModel = MainViewModel()
    @State private var downloadViewModel = DownloadViewModel()
    @State private var settingsViewModel = SettingsViewModel()

    // 言語変更時にView全体を再構築するためのキー
    @AppStorage("language") private var language = AppLanguage.system.rawValue
    @AppStorage("menuBarEnabled") private var menuBarEnabled = false

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
        }

        Settings {
            SettingsView()
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
