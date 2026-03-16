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

    static var defaultDownloadDirectory: String {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "~/Downloads"
    }

    static var downloadDirectoryURL: URL {
        URL(fileURLWithPath: downloadDirectory)
    }

    static let outputTemplatePresets: [(name: String, template: String)] = [
        ("タイトル", "%(title)s.%(ext)s"),
        ("タイトル + ID", "%(title)s [%(id)s].%(ext)s"),
        ("チャンネル / タイトル", "%(uploader)s/%(title)s.%(ext)s"),
        ("日付 - タイトル", "%(upload_date)s - %(title)s.%(ext)s"),
    ]
}
