//
//  ErrorCell.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//

import Foundation
import UIKit

extension BlockEditor {
    /// An error cell for when we don't know what else to display
    class ErrorCell:
        UICollectionViewCell,
        Identifiable,
        BlockCellProtocol
    {
        static let identifier = "ErrorCell"
        
        var id: UUID = UUID()
        private lazy var label = UILabel(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.themeDefault()
            label.text = String(localized: "Unknown cell type")
            contentView.addSubview(label)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
