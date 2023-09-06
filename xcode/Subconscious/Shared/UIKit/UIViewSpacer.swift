//
//  UIViewSpacer.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit

extension UIView {
    /// Create a SwiftUI-like spacer view
    static func spacer() -> UIView {
        let spacerView = UIView()
        spacerView.isUserInteractionEnabled = false
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacerView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        return spacerView
    }
}
