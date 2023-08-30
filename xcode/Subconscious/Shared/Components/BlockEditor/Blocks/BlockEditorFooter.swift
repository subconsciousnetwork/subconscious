//
//  BlockEditorFooter.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//

import UIKit

extension BlockEditor {
    class Footer: UICollectionReusableView {
        /// Reuse identifier for UICollectionView
        static let identifier = "BlockEditorFooter"

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .red
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
