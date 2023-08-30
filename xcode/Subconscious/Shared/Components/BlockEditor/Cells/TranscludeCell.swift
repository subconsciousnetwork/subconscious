//
//  FooterCell.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//

import Foundation
import UIKit

extension BlockEditor {
    class TranscludeCell:
        UICollectionViewCell,
        Identifiable
    {
        static let identifier = "TranscludeCell"
        
        var id: UUID = UUID()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .red
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(_ state: TranscludeModel) {
            self.id = state.id
        }
    }
}
