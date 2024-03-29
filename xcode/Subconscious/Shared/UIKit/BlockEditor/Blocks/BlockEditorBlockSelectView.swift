//
//  BlockEditorBlockSelectView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/15/23.
//

import UIKit

extension BlockEditor {
    /// A rounded rect view that is used as the background of BlockEditor blocks
    /// when in block select mode.
    class BlockSelectView: UIView {
        private var borderColor = UIColor.accent

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.backgroundColor = UIColor.accent.withAlphaComponent(0.1).cgColor
            layer.borderWidth = 1
            layer.borderColor = UIColor.accent.cgColor
            layer.cornerRadius = AppTheme.cornerRadius
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
