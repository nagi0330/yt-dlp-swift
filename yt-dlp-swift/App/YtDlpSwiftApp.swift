import SwiftUI

@main
struct YtDlpSwiftApp: App {
    @State private var dependencyViewModel = DependencyViewModel()
    @State private var mainViewModel = MainViewModel()
    @State private var downloadViewModel = DownloadViewModel()
    @State private var settingsViewModel = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(dependencyViewModel)
                .environment(mainViewModel)
                .environment(downloadViewModel)
                .environment(settingsViewModel)
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
        }
    }
}
