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

enum BlockEditorAction: Hashable {
    case appear(MemoEditorDetailDescription)
    case scenePhaseChange(ScenePhase)
    case setLoadingState(LoadingState)
    case sendMessage(String)
    case receiveMessage(String)
    case autosave
}

struct BlockEditorModel: ModelProtocol {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "BlockEditorModel"
    )
    typealias Action = BlockEditorAction
    typealias Environment = AppEnvironment

    var loadingState: LoadingState = .loading
    var url: URL
    var javaScript: String

    init(
        url: URL,
        javaScript: String
    ) {
        self.url = url
        self.javaScript = javaScript
    }

    private func toJSON() -> String {
        return "{}"
    }

    static func update(
        state: Self,
        action: Action,
        environment: AppEnvironment
    ) -> Update<Self> {
        switch action {
        case .appear(_):
            return Update(state: state)
        case .scenePhaseChange:
            return Update(state: state)
        case .autosave:
            return Update(state: state)
        case let .setLoadingState(loadingState):
            return setLoadingState(
                state: Self,
                loadingState
            )
        case .sendMessage(_):
            return Update(state: state)
        case .receiveMessage(_):
            return Update(state: state)
        }
    }

    private func setLoadingState(
        state: Self,
        loadingState: LoadingState
    ) -> Update<Self> {
        var model = state
        model.loadingState = loadingState
        if case .loaded = loadingState {
            let fx: Fx<Self.Action> = Future.detached {
                .sendMessage(self.toJSON())
            }.eraseToAnyPublisher()

            return UpdateType(state: model, fx: fx)
        }
        return Update(state: state)
    }
}

struct BlockEditorWebViewRepresentable: UIViewRepresentable {
    private static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "BlockEditorWebViewRepresentable"
    )

    private var storeDidChangeCancellable: AnyCancellable? = nil

    typealias Store = ObservableStore.Store<BlockEditorModel>
    var store: Store

    init(store: Store) {
        self.store = store
    }

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

    @MainActor
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self.store)
    }

    class Coordinator: NSObject {
        private static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditorWebViewRepresentableCoordinator"
        )

        private var store: Store
        private var url: URL? = nil

        init(
            _ store: Store
        ) {
            self.store = store
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @MainActor
        func update(_ webView: WKWebView) {
            Self.logger.debug("Update")
            let url = store.state.url
            if (self.url != url) {
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
        if let json = message.body as? String {
            Task { @MainActor in
                store.send(.receiveMessage(json))
            }
        }
    }
}

extension BlockEditorWebViewRepresentable.Coordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Self.logger.info("Navigation finished \(self.url?.description ?? "")")
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
