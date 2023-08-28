//
//  BlockFormatMenu.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/26/23.
//

import UIKit

extension UIMenu {
    static func blockFormatMenu(
        onBold: @escaping () -> Void,
        onItalic: @escaping () -> Void,
        onCode: @escaping () -> Void
    ) -> UIMenu {
        let bold = UIAction(
            title: "Bold",
            image: UIImage(systemName: "bold")
        ) { _ in
            onBold()
        }
        let italic = UIAction(
            title: "Italic",
            image: UIImage(systemName: "italic")
        ) { _ in
            onItalic()
        }
        let code = UIAction(
            title: "Code",
            image: UIImage(systemName: "curlybraces")
        ) { _ in
            onCode()
        }

        let menu = UIMenu(
            title: "Formatting",
            image: UIImage(systemName: "textformat"),
            children: [bold, italic, code]
        )
        return menu
    }
}
