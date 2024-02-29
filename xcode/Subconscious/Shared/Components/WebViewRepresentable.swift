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
    /// The "origin" URL for the file. That is, the directory that content
    /// is allowed to be loaded from. If you leave this empty, it will default
    /// to the parent directory of `url`.
    var origin: URL?
    /// JavaScript to run in the context of the WebView.
    /// You can use this to send data down.
    var javaScript = ""
    /// Closure to receive post messages from JavaScript land
    var receiveMessage: (String) -> Void
    var showsHorizontalScrollIndicator = true
    var showsVerticalScrollIndicator = true
    var isBackgroundClear: Bool = false
    // The name of the API method you'll use in JavaScript to send messages
    var messageHandlerName = "native"

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Required to load modules from local file system
        configuration.preferences.setValue(
            true,
            forKey: "allowFileAccessFromFileURLs"
        )
        // We'll use this to set up a communication channel with the WebView
        let contentController = WKUserContentController()
        // name is the name you'll use in JavaScript to send messages
        contentController.add(context.coordinator, name: messageHandlerName)
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)

        webView.scrollView
            .showsVerticalScrollIndicator = showsVerticalScrollIndicator
        webView.scrollView
            .showsHorizontalScrollIndicator = showsHorizontalScrollIndicator

        if isBackgroundClear {
            webView.setBackgroundClear()
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        private static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "LocalWebViewRepresentableCoordinator"
        )

        var view: LocalWebViewRepresentable
        private var url: URL?
        private var javaScript = ""

        init(
            _ view: LocalWebViewRepresentable
        ) {
            self.view = view
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(_ webView: WKWebView) {
            loadIfNeeded(webView: webView)
            evaluateJavaScriptIfNeeded(webView: webView)
        }

        @discardableResult
        func loadIfNeeded(webView: WKWebView) -> WKNavigation? {
            // Already loaded. Skip.
            guard self.url != self.view.url else {
                Self.logger.debug("URL already loaded. Skipping")
                return nil
            }
            guard let url = view.url else {
                Self.logger.debug("No URL")
                return nil
            }
            guard url.isFileURL else {
                Self.logger.debug("Not a file URL. Use `WebViewRepresentable` to load remote resources")
                return nil
            }
            // Update coordinator state
            self.url = url
            let request = URLRequest(url: url)
            Self.logger.info("Loading \(url)")
            return webView.loadFileRequest(
                request,
                // Allow access to origin URL, or parent directory by default
                allowingReadAccessTo:
                    view.origin ?? url.deletingLastPathComponent()
            )
        }

        func evaluateJavaScriptIfNeeded(webView: WKWebView) {
            guard self.view.javaScript != "" else {
                return
            }
            guard self.javaScript != self.view.javaScript else {
                return
            }
            self.javaScript = self.view.javaScript
            webView.evaluateJavaScript(self.javaScript)
            Self.logger.info("Evaluated JavaScript")
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == view.messageHandlerName {
                // Handle the message
                if let messageBody = message.body as? String {
                    view.receiveMessage(messageBody)
                }
            }
        }
    }
}


struct WebViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        LocalWebViewRepresentable(
            url: Bundle.main.url(
                forResource: "index",
                withExtension: "html",
                subdirectory: "Assets"
            ),
            receiveMessage: { message in }
        )
        WebViewRepresentable(
            url: URL(string: "https://example.com")
        )
    }
}
