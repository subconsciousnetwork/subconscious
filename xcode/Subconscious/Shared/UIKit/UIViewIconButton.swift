//
//  BlockToolbarButtonUIView.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit

extension UIView {
    // Create an icon button.
    // By default, button autolayout is set to the default minimum touch
    // target size.
    static func iconButton(
        icon: UIImage?,
        width: CGFloat = 44,
        height: CGFloat = 44
    ) -> UIButton {
        let button = UIButton()
        button.setImage(icon, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonWidth = button.widthAnchor.constraint(
            equalToConstant: width
        )
        buttonWidth.isActive = true
        
        let buttonHeight = button.widthAnchor.constraint(
            equalToConstant: width
        )
        buttonHeight.isActive = true
        
        return button
    }
}
