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
        Identifiable
    {
        static let identifier = "RelatedCell"
        
        var id: UUID = UUID()
        private lazy var relatedView = RelatedView(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            relatedView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(relatedView)
            NSLayoutConstraint.activate([
                relatedView.leadingAnchor.constraint(equalTo: leadingAnchor),
                relatedView.trailingAnchor.constraint(equalTo: trailingAnchor),
                relatedView.topAnchor.constraint(equalTo: topAnchor),
                bottomAnchor.constraint(equalTo: relatedView.bottomAnchor),
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
