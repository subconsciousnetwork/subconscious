//
//  WKWebViewHelpers.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/1/24.
//

import Foundation
import WebKit

extension WKWebView {
    /// Wrap the callback form of `evaluateJavaScript` because the built-in
    /// async version just crashes.
    /// Workaround for https://forums.developer.apple.com/forums/thread/701553
    @discardableResult
    @MainActor
    func evaluateJavaScriptAsync(_ str: String) async throws -> Any? {
        return try await withCheckedThrowingContinuation {
           (continuation: CheckedContinuation<Any?, Error>) in
            // Ignore this warning. The async flavor of
            // evaluateJavascript crashes.
            // See https://forums.developer.apple.com/forums/thread/701553
            self.evaluateJavaScript(str) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }
}

extension WKWebView {
    func setBackgroundClear() {
        self.backgroundColor = .clear
        self.scrollView.backgroundColor = .clear
        self.isOpaque = false
    }
}

extension WKWebView {
    /// Set scroll indicators
    func showScrollIndicator(horizontal: Bool, vertical: Bool) {
        self.scrollView.showsVerticalScrollIndicator = vertical
        self.scrollView.showsHorizontalScrollIndicator = horizontal

    }
}

extension WKWebViewConfiguration {
    /// Create a preconfigured configuration object that allows WKWebView
    /// to load local files from the bundle.
    static func forLocalFiles() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        // Required to load modules from local file system
        configuration.preferences.setValue(
            true,
            forKey: "allowFileAccessFromFileURLs"
        )
        return configuration
    }
}
