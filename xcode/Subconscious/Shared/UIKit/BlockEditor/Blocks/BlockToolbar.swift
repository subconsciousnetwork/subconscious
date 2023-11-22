//
//  BlockToolbarUIView.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import Foundation
import UIKit

extension UIToolbar {
    static func blockToolbar(
        upButtonPressed: @escaping () -> Void,
        downButtonPressed: @escaping () -> Void,
        boldButtonPressed: @escaping () -> Void,
        italicButtonPressed: @escaping () -> Void,
        codeButtonPressed: @escaping () -> Void,
        dismissKeyboardButtonPressed: @escaping () -> Void
    ) -> UIToolbar {
        let toolbar = UIToolbar()

        let upButton = UIBarButtonItem(
            title: String(localized: "Move block up"),
            image: UIImage(systemName: "chevron.up"),
            handle: upButtonPressed
        )

        let downButton = UIBarButtonItem(
            title: String(localized: "Move block down"),
            image: UIImage(systemName: "chevron.down"),
            handle: downButtonPressed
        )

        let spacer = UIBarButtonItem.flexibleSpace()
        
        let formatMenu = UIMenu.blockFormatMenu(
            onBold: boldButtonPressed,
            onItalic: italicButtonPressed,
            onCode: codeButtonPressed
        )

        let formatButton = UIBarButtonItem(
            title: String(localized: "Formatting"),
            image: UIImage(systemName: "textformat"),
            menu: formatMenu
        )
        
        let dismissKeyboardButton = UIBarButtonItem(
            title: String(localized: "Dismiss keyboard"),
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            handle: dismissKeyboardButtonPressed
        )

        toolbar.setItems(
            [
                upButton,
                downButton,
                spacer,
                formatButton,
                dismissKeyboardButton
            ],
            animated: false
        )
        toolbar.isTranslucent = false
        toolbar.sizeToFit()
        return toolbar
    }
}
