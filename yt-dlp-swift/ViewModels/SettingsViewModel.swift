import Foundation
import SwiftUI

@MainActor
@Observable
class SettingsViewModel {
    var downloadDirectory: String = AppSettings.downloadDirectory
    var defaultPreset: String = AppSettings.defaultPreset
    var maxConcurrentDownloads: Int = AppSettings.maxConcurrentDownloads
    var outputTemplate: String = AppSettings.outputTemplate
    var clipboardMonitoring: Bool = AppSettings.clipboardMonitoring
    var extraArguments: String = AppSettings.extraArguments
    var preferredContainer: String = AppSettings.preferredContainer
    var language: String = AppSettings.language
    var menuBarEnabled: Bool = AppSettings.menuBarEnabled
    var playlistBehavior: String = AppSettings.playlistBehavior
    var ytDlpPath: String = AppSettings.ytDlpPath
    var ytDlpCustomPath: String = AppSettings.ytDlpCustomPath

    func save() {
        AppSettings.downloadDirectory = downloadDirectory
        AppSettings.defaultPreset = defaultPreset
        AppSettings.maxConcurrentDownloads = maxConcurrentDownloads
        AppSettings.outputTemplate = outputTemplate
        AppSettings.clipboardMonitoring = clipboardMonitoring
        AppSettings.extraArguments = extraArguments
        AppSettings.preferredContainer = preferredContainer
        AppSettings.language = language
        AppSettings.menuBarEnabled = menuBarEnabled
        AppSettings.playlistBehavior = playlistBehavior
        AppSettings.ytDlpPath = ytDlpPath
        AppSettings.ytDlpCustomPath = ytDlpCustomPath
    }

    func chooseDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.title = L10n.chooseDownloadFolder
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url.path
            AppSettings.downloadDirectory = url.path
        }
    }
}
