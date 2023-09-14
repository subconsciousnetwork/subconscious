//
//  UIStackViewHelpers.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit

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
