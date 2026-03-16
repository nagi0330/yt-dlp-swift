import Foundation
import SwiftUI

@Observable
class SettingsViewModel {
    var downloadDirectory: String = AppSettings.downloadDirectory
    var defaultPreset: String = AppSettings.defaultPreset
    var maxConcurrentDownloads: Int = AppSettings.maxConcurrentDownloads
    var outputTemplate: String = AppSettings.outputTemplate
    var clipboardMonitoring: Bool = AppSettings.clipboardMonitoring
    var extraArguments: String = AppSettings.extraArguments
    var preferredContainer: String = AppSettings.preferredContainer

    func save() {
        AppSettings.downloadDirectory = downloadDirectory
        AppSettings.defaultPreset = defaultPreset
        AppSettings.maxConcurrentDownloads = maxConcurrentDownloads
        AppSettings.outputTemplate = outputTemplate
        AppSettings.clipboardMonitoring = clipboardMonitoring
        AppSettings.extraArguments = extraArguments
        AppSettings.preferredContainer = preferredContainer
    }

    func chooseDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.title = "ダウンロード先フォルダを選択"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url.path
            AppSettings.downloadDirectory = url.path
        }
    }
}
