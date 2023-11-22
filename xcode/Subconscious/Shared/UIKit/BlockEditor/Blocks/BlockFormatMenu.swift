//
//  BlockFormatMenu.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/26/23.
//

import UIKit

extension BlockEditor {
    enum BlockFormatMenuAction: Hashable {
        case boldButtonPressed
        case italicButtonPressed
        case codeButtonPressed
    }
}

extension UIMenu {
    static func blockFormatMenu(
        send: @escaping (BlockEditor.BlockFormatMenuAction) -> Void
    ) -> UIMenu {
        let bold = UIAction(
            title: "Bold",
            image: UIImage(systemName: "bold")
        ) { _ in
            send(.boldButtonPressed)
        }
        let italic = UIAction(
            title: "Italic",
            image: UIImage(systemName: "italic")
        ) { _ in
            send(.italicButtonPressed)
        }
        let code = UIAction(
            title: "Code",
            image: UIImage(systemName: "curlybraces")
        ) { _ in
            send(.codeButtonPressed)
        }

        let menu = UIMenu(
            title: "Formatting",
            image: UIImage(systemName: "textformat"),
            children: [bold, italic, code]
        )
        return menu
    }
}
