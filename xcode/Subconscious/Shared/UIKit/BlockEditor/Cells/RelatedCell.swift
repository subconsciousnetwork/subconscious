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
        UIViewComponentProtocol
    {
        static let identifier = "RelatedCell"
        
        var id: UUID = UUID()
        private var margins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        private lazy var relatedView = RelatedView(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.directionalLayoutMargins = margins
            relatedView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(relatedView)
            
            let marginsGuide = self.layoutMarginsGuide
            NSLayoutConstraint.activate([
                relatedView.leadingAnchor.constraint(
                    equalTo: marginsGuide.leadingAnchor
                ),
                relatedView.trailingAnchor.constraint(
                    equalTo: marginsGuide.trailingAnchor
                ),
                relatedView.topAnchor.constraint(
                    equalTo: marginsGuide.topAnchor
                ),
                relatedView.bottomAnchor.constraint(
                    equalTo: marginsGuide.bottomAnchor
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
