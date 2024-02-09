//
//  WebViewRepresentable.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/9/24.
//

import SwiftUI
import WebKit
import os

extension WKWebView {
    func setBackgroundClear() {
        self.backgroundColor = .clear
        self.scrollView.backgroundColor = .clear
        self.isOpaque = false
    }
}

/// SwiftUI wrapper for WKWebView
struct WebViewRepresentable: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "WebViewRepresentable"
    )
    typealias UIViewType = WKWebView

    var url: URL?
    var isBackgroundClear: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        /// Required to load modules from local file system
        configuration.preferences.setValue(
            true,
            forKey: "allowFileAccessFromFileURLs"
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        if isBackgroundClear {
            webView.setBackgroundClear()
        }
        return webView
    }

    @discardableResult
    func load(webView: WKWebView, url: URL?) -> WKNavigation? {
        guard let url = url else {
            Self.logger.debug("No URL")
            return nil
        }
        let request = URLRequest(url: url)
        return webView.load(request)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        load(webView: webView, url: url)
    }
}

/// SwiftUI wrapper for WKWebView, optimized for loading local files from the
/// bundle and displaying them.
///
/// Loading files from the bundle requires a number of special settings,
/// including toggling certain properties of the WebView to allow for things
/// like JS modules to load. This view takes care of that.
struct LocalWebViewRepresentable: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "LocalWebViewRepresentable"
    )

    typealias UIViewType = WKWebView
    var url: URL?
    var origin: URL?
    var isBackgroundClear: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        /// Required to load modules from local file system
        configuration.preferences.setValue(
            true,
            forKey: "allowFileAccessFromFileURLs"
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        if isBackgroundClear {
            webView.setBackgroundClear()
        }
        return webView
    }
    
    @discardableResult
    func load(webView: WKWebView, url: URL?) -> WKNavigation? {
        guard let url = url else {
            Self.logger.debug("No URL")
            return nil
        }
        guard url.isFileURL else {
            Self.logger.debug("Not a file URL. Use `WebViewRepresentable` to load remote resources")
            return nil
        }
        let request = URLRequest(url: url)
        return webView.loadFileRequest(
            request,
            // Allow access to origin URL, or parent directory by default
            allowingReadAccessTo: origin ?? url.deletingLastPathComponent()
        )
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        load(webView: webView, url: url)
    }
}


struct WebViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        LocalWebViewRepresentable(
            url: Bundle.main.url(
                forResource: "index",
                withExtension: "html",
                subdirectory: "Assets"
            )
        )
        WebViewRepresentable(
            url: URL(string: "https://example.com")
        )
    }
}
