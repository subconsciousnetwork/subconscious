//
//  FooterCell.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//

import Foundation
import UIKit

extension BlockEditor {
    /// Displays related notes
    class RelatedCell:
        UICollectionViewCell,
        UIComponentViewProtocol
    {
        static let identifier = "RelatedCell"
        
        var id: UUID = UUID()
        private var padding = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )
        private lazy var relatedView = RelatedView(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            relatedView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(relatedView)
            NSLayoutConstraint.activate([
                relatedView.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: padding.left
                ),
                relatedView.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -1 * padding.right
                ),
                relatedView.topAnchor.constraint(
                    equalTo: topAnchor,
                    constant: padding.top
                )
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(_ state: RelatedModel) {
            self.id = state.id
            relatedView.render(state)
        }
    }
}
