//
//  UIView+Separator.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/27/23.
//

import UIKit

extension UIView {
    /// Create a divider.
    /// Sets a height constraint, but does not set other constraints.
    static func divider(height: CGFloat = 0.5) -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        let heightAnchor = divider.heightAnchor.constraint(
            equalToConstant: height
        )
        heightAnchor.isActive = true
        divider.backgroundColor = .separator
        return divider
    }
}
