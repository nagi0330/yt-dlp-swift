import SwiftUI
import WebKit

// ログイン用のWebKitブラウザウィンドウ
struct LoginWebView: View {
    let site: SiteInfo
    let onComplete: () -> Void

    @State private var currentURL: String = ""
    @State private var isLoading = true
    @State private var pageTitle: String = ""
    @State private var isSaving = false
    @State private var saveMessage: String?
    @Environment(\.dismiss) private var dismiss

    // サイトごとに独立したWKWebViewの設定を使用
    @State private var webViewStore = WebViewStore()

    var body: some View {
        VStack(spacing: 0) {
            // ツールバー
            HStack(spacing: 8) {
                // 戻る・進む
                Button {
                    webViewStore.webView?.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!(webViewStore.webView?.canGoBack ?? false))

                Button {
                    webViewStore.webView?.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!(webViewStore.webView?.canGoForward ?? false))

                Button {
                    webViewStore.webView?.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                // URL表示
                Text(currentURL)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(8)
            .background(.bar)

            Divider()

            // WebView
            WebViewRepresentable(store: webViewStore, currentURL: $currentURL, isLoading: $isLoading, pageTitle: $pageTitle)

            Divider()

            // フッター
            HStack {
                if let msg = saveMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(msg == L10n.cookieSaved ? .green : .red)
                }

                Spacer()

                Button(L10n.cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    Task { await saveCookies() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(L10n.saveCookiesAndLogin)
                    }
                }
                .disabled(isSaving)
                .keyboardShortcut(.defaultAction)
            }
            .padding(8)
            .background(.bar)
        }
        .onAppear {
            if let urlString = site.url, let url = URL(string: urlString) {
                webViewStore.load(url)
            }
        }
    }

    private func saveCookies() async {
        isSaving = true
        saveMessage = nil

        do {
            guard let dataStore = webViewStore.webView?.configuration.websiteDataStore else {
                saveMessage = L10n.webViewInitFailed
                isSaving = false
                return
            }

            try await CookieManager.shared.exportCookies(
                from: dataStore,
                for: site.extractorPattern,
                siteURL: site.url
            )
            saveMessage = L10n.cookieSaved
            isSaving = false

            // 少し待ってから閉じる
            try? await Task.sleep(for: .seconds(1))
            onComplete()
            dismiss()
        } catch {
            saveMessage = L10n.saveError(error.localizedDescription)
            isSaving = false
        }
    }
}

// WKWebViewの状態を保持するストア
@Observable
class WebViewStore {
    var webView: WKWebView?

    func load(_ url: URL) {
        let config = WKWebViewConfiguration()
        // 非永続でないデータストアを使用 (cookieを保持するため)
        config.websiteDataStore = .default()

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        self.webView = wv
        wv.load(URLRequest(url: url))
    }
}

// NSViewRepresentable でWKWebViewをSwiftUIに統合
struct WebViewRepresentable: NSViewRepresentable {
    let store: WebViewStore
    @Binding var currentURL: String
    @Binding var isLoading: Bool
    @Binding var pageTitle: String

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        context.coordinator.observeWebView(store: store, container: container)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.observeWebView(store: store, container: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable
        private var urlObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private weak var currentWebView: WKWebView?

        init(parent: WebViewRepresentable) {
            self.parent = parent
        }

        func observeWebView(store: WebViewStore, container: NSView) {
            guard let webView = store.webView, webView !== currentWebView else { return }
            currentWebView = webView

            webView.navigationDelegate = self

            // 既存のwebviewがcontainerにいなければ追加
            if webView.superview !== container {
                container.subviews.forEach { $0.removeFromSuperview() }
                webView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(webView)
                NSLayoutConstraint.activate([
                    webView.topAnchor.constraint(equalTo: container.topAnchor),
                    webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                    webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                ])
            }

            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.parent.currentURL = wv.url?.absoluteString ?? ""
                }
            }
            loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.parent.isLoading = wv.isLoading
                }
            }
            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.parent.pageTitle = wv.title ?? ""
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
