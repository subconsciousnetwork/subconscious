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
        UICollectionViewCell
    {
        static let identifier = "RelatedCell"
        
        var id: UUID = UUID()
        private var relatedHostingView = UIHostingView<BacklinksView>()

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            relatedHostingView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(relatedHostingView)
            
            relatedHostingView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            
            relatedHostingView.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )

            setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )

            setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )

            NSLayoutConstraint.activate([
                relatedHostingView.leadingAnchor.constraint(
                    equalTo: leadingAnchor
                ),
                relatedHostingView.trailingAnchor.constraint(
                    equalTo: trailingAnchor
                ),
                relatedHostingView.topAnchor.constraint(
                    equalTo: topAnchor
                ),
                relatedHostingView.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                ),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        func update(
            parentController: UIViewController,
            state: BlockEditor.RelatedModel
        ) {
            self.id = state.id
            relatedHostingView.update(
                parentController: parentController,
                rootView: BacklinksView(
                    backlinks: state.related,
                    onRequestDetail: { _ in },
                    onLink: { _, _ in }
                )
            )
        }
    }
}

struct BlockEditorRelatedCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let controller = UIViewController()
            let view = BlockEditor.RelatedCell()
            view.update(
                parentController: controller,
                state: BlockEditor.RelatedModel(
                    related: [
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/foo")!,
                            excerpt: Subtext(markup: "An [[autopoietic system]] is a network of processes that recursively depend on each other for their own generation and realization."),
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
