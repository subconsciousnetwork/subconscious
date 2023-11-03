//
//  RelatedCell.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/30/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    /// Displays related notes
    class RelatedCell:
        UICollectionViewCell,
        UIViewComponentProtocol
    {
        static let identifier = "RelatedCell"
        
        var id: UUID = UUID()
        private var margins = NSDirectionalEdgeInsets(
            top: AppTheme.padding,
            leading: AppTheme.padding,
            bottom: AppTheme.padding,
            trailing: AppTheme.padding
        )
        private var relatedView = RelatedView(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.directionalLayoutMargins = margins
            
            relatedView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(relatedView)
            
            setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            let marginsGuide = contentView.layoutMarginsGuide
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
        
        override func prepareForReuse() {
            relatedView.render(BlockEditor.RelatedModel())
        }

        func render(_ state: BlockEditor.RelatedModel) {
            self.id = state.id
            relatedView.render(state)
        }
    }
}

struct BlockEditorRelatedCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.RelatedCell()
            view.render(
                BlockEditor.RelatedModel(
                    related: [
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/foo")!,
                            excerpt: Subtext(markup: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization."),
                            isTruncated: true,
                            modified: Date.now
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/bar")!,
                            excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                            isTruncated: false,
                            modified: Date.now
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/baz")!,
                            excerpt: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
                            isTruncated: true,
                            modified: Date.now
                        )
                    ]
                )
            )
            return view
        }
    }
}