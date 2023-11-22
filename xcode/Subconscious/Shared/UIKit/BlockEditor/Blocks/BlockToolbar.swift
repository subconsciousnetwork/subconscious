//
//  BlockToolbarUIView.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import Foundation
import UIKit

extension BlockEditor {
    enum BlockToolbarAction: Hashable {
        case upButtonPressed
        case downButtonPressed
        case dismissKeyboardButtonPressed
        case formatMenu(BlockFormatMenuAction)
    }
}

extension UIToolbar {
    static func blockToolbar(
        send: @escaping (BlockEditor.BlockToolbarAction) -> Void
    ) -> UIToolbar {
        let toolbar = UIToolbar()

        let upButton = UIBarButtonItem(
            title: String(localized: "Move block up"),
            image: UIImage(systemName: "chevron.up"),
            handle: {
                send(.upButtonPressed)
            }
        )

        let downButton = UIBarButtonItem(
            title: String(localized: "Move block down"),
            image: UIImage(systemName: "chevron.down"),
            handle: {
                send(.downButtonPressed)
            }
        )

        let spacer = UIBarButtonItem.flexibleSpace()
        
        let formatMenu = UIMenu.blockFormatMenu(
            send: { action in
                send(.formatMenu(action))
            }
        )

        let formatButton = UIBarButtonItem(
            title: String(localized: "Formatting"),
            image: UIImage(systemName: "textformat"),
            menu: formatMenu
        )
        
        let dismissKeyboardButton = UIBarButtonItem(
            title: String(localized: "Dismiss keyboard"),
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            handle: {
                send(.dismissKeyboardButtonPressed)
            }
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
