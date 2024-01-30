//
//  UIStackViewHelpers.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit

extension UIStackView {
    @discardableResult
    func vStack() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = .vertical
        self.alignment = .fill
        self.distribution = .fill
        self.spacing = 0
        self.setContentHuggingPriority(
            .defaultHigh,
            for: .vertical
        )
        return self
    }

    @discardableResult
    func hStack() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = .horizontal
        self.alignment = .fill
        self.distribution = .fill
        self.spacing = 0
        self.setContentHuggingPriority(
            .defaultHigh,
            for: .vertical
        )
        return self
    }
}

extension UIStackView {
    /// Remove a view from a UIViewStack completely.
    ///
    /// `.removeArrangedSubview()` removes view from arranged views,
    /// however, it does not remove it from subviews.
    /// This alternative method removes the view from the superview completely.
    func removeArrangedSubviewCompletely(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}

extension UIStackView {
    /// Remove all arranged subviews from this stack view
    func removeAllArrangedSubviewsCompletely() {
        for view in arrangedSubviews {
            removeArrangedSubviewCompletely(view: view)
        }
    }
}
