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
import Observation
import Arboreal

enum BlockEditorAction: Hashable {
    case appear(MemoEditorDetailDescription)
    case scenePhaseChange(ScenePhase)
    case setLoadingState(LoadingState)
    case sendMessage(String)
    case receiveMessage(String)
    case autosave
}

struct BlockEditorDoc: Hashable, Codable {

}

@Observable
final class BlockEditorModel: ArborealModel {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "BlockEditorModel"
    )
    typealias Action = BlockEditorAction
    typealias Environment = AppEnvironment

    var loadingState: LoadingState = .loading
    var doc: BlockEditorDoc

    init(
        doc: BlockEditorDoc
    ) {
        self.doc = doc
    }

    private func toJSON() -> String {
        return "{}"
    }

    func update(
        action: Action,
        environment: AppEnvironment
    ) -> Fx<BlockEditorAction> {
        switch action {
        case .appear(_):
            return Fx.none
        case .scenePhaseChange:
            return Fx.none
        case .autosave:
            return Fx.none
        case let .setLoadingState(loadingState):
            return setLoadingState(
                loadingState: loadingState
            )
        case .sendMessage(_):
            return Fx.none
        case .receiveMessage(_):
            return Fx.none
        }
    }

    private func setLoadingState(
        loadingState: LoadingState
    ) -> Fx<BlockEditorAction> {
        self.loadingState = loadingState
        if case .loaded = loadingState {
            return Fx {
                .sendMessage(self.toJSON())
            }
        }
        return Fx.none
    }
}

struct BlockEditorWebViewRepresentable: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "BlockEditorWebViewRepresentable"
    )

    typealias Store = Arboreal.Store<BlockEditorModel>
    var store: Store
    var url: URL

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

        context.coordinator.setup(webView, url: url)

        return webView
    }

    @MainActor
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: self.store)
    }

    class Coordinator: NSObject {
        private static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditorWebViewRepresentableCoordinator"
        )

        private var store: Store
        private var doc: BlockEditorDoc? = nil

        @MainActor
        init(
            store: Store
        ) {
            self.store = store
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setup(
            _ webView: WKWebView,
            url: URL
        ) {
            webView.load(URLRequest(url: url))
        }

        @MainActor
        func update(_ webView: WKWebView) {
            Self.logger.debug("Update")
            webView.evaluateJavaScript(
                """
                window.postMessage("hello")
                """
            )
        }
    }
}

extension BlockEditorWebViewRepresentable.Coordinator: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if let json = message.body as? String {
            Task { @MainActor in
                store.send(.receiveMessage(json))
            }
        }
    }
}

extension BlockEditorWebViewRepresentable.Coordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Self.logger.info("Navigation finished")
        Task { @MainActor in
            store.send(.setLoadingState(.loaded))
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        Self.logger.info("Navigation failed: \(error.localizedDescription)")
        Task { @MainActor in
            store.send(.setLoadingState(.notFound))
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        Self.logger.info("Provisional navigation failed: \(error.localizedDescription)")
        Task { @MainActor in
            store.send(.setLoadingState(.notFound))
        }
    }
}
