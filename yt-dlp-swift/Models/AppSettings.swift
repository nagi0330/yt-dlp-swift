import Foundation
import SwiftUI

// UserDefaultsに保存するアプリ設定
struct AppSettings {
    @AppStorage("downloadDirectory") static var downloadDirectory: String = defaultDownloadDirectory
    @AppStorage("defaultPreset") static var defaultPreset: String = DownloadPreset.bestVideo.rawValue
    @AppStorage("maxConcurrentDownloads") static var maxConcurrentDownloads: Int = 3
    @AppStorage("outputTemplate") static var outputTemplate: String = "%(title)s.%(ext)s"
    @AppStorage("clipboardMonitoring") static var clipboardMonitoring: Bool = false
    @AppStorage("extraArguments") static var extraArguments: String = ""
    @AppStorage("preferredContainer") static var preferredContainer: String = VideoContainer.mp4.rawValue
    @AppStorage("language") static var language: String = AppLanguage.system.rawValue
    @AppStorage("menuBarEnabled") static var menuBarEnabled: Bool = false

    static var defaultDownloadDirectory: String {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "~/Downloads"
    }

    static var downloadDirectoryURL: URL {
        URL(fileURLWithPath: downloadDirectory)
    }

    static var outputTemplatePresets: [(name: String, template: String)] {
        [
            (L10n.templateTitle, "%(title)s.%(ext)s"),
            (L10n.templateTitleID, "%(title)s [%(id)s].%(ext)s"),
            (L10n.templateChannelTitle, "%(uploader)s/%(title)s.%(ext)s"),
            (L10n.templateDateTitle, "%(upload_date)s - %(title)s.%(ext)s"),
        ]
    }
}
