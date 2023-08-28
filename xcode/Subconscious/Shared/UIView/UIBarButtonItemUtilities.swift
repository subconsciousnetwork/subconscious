//
//  UIBarButtonItemUtilities.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/25/23.
//

import UIKit

extension UIBarButtonItem {
    convenience init(
        title: String? = nil,
        image: UIImage? = nil,
        handle: @escaping () -> Void,
        menu: UIMenu? = nil
    ) {
        self.init(
            title: title,
            image: image,
            primaryAction: UIAction(
                handler: { _ in handle() }
            ),
            menu: menu
        )
    }
}
