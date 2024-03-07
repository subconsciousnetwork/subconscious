//
//  WebViewRepresentable.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/9/24.
//

import SwiftUI
import WebKit
import os
import Combine
import ObservableStore

struct BlockEditorWebViewRepresentable: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "BlockEditorWebViewRepresentable"
    )

    var url: URL
    var javaScript: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration.forLocalFiles()
        // We'll use this to set up a communication channel with the WebView
        let contentController = WKUserContentController()
        // name is the name you'll use in JavaScript to send messages
        contentController.add(context.coordinator, name: "native")
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.showScrollIndicator(horizontal: false, vertical: false)
        webView.setBackgroundClear()

        webView.navigationDelegate = context.coordinator

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        private static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditorWebViewRepresentableCoordinator"
        )

        private var view: BlockEditorWebViewRepresentable

        var url: URL? = nil
        var javaScript: String = ""

        init(
            _ view: BlockEditorWebViewRepresentable
        ) {
            self.view = view
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(_ webView: WKWebView) {
            if (url != view.url) {
                let url = view.url
                self.url = url
                webView.load(URLRequest(url: url))
            }
        }
    }
}

extension BlockEditorWebViewRepresentable.Coordinator: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
    }
}

extension BlockEditorWebViewRepresentable.Coordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Self.logger.info("Navigation finished \(self.url?.description ?? "")")
        Task { @MainActor in
            do {
                try await webView.evaluateJavaScriptAsync(javaScript)
            } catch {
                Self.logger.info("Script evaluation failed: \(error.localizedDescription)")
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        Self.logger.info("Navigation failed: \(error.localizedDescription)")
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        Self.logger.info("Provisional navigation failed: \(error.localizedDescription)")
    }
}
