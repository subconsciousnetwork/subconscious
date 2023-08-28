//
//  UIViewSpacer.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit

extension UIView {
    static func spacer() -> UIView {
        let spacerView = UIView(frame: .zero)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        let spacerWidthConstraint = spacerView.widthAnchor.constraint(
            equalToConstant: .greatestFiniteMagnitude
        )
        // ensures it will not "overgrow"
        spacerWidthConstraint.priority = .defaultLow
        spacerWidthConstraint.isActive = true
        let spacerHeightConstraint = spacerView.heightAnchor.constraint(
            equalToConstant: .greatestFiniteMagnitude
        )
        // ensures it will not "overgrow"
        spacerHeightConstraint.priority = .defaultLow
        spacerHeightConstraint.isActive = true
        return spacerView
    }
}
