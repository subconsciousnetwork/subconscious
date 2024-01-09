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
        
        var send: (RelatedAction) -> Void = { _ in }
        
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
            
            relatedHostingView.setContentCompressionResistancePriority(
                .defaultLow,
                for: .horizontal
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
                    equalTo: contentView.leadingAnchor
                ),
                relatedHostingView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                relatedHostingView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                relatedHostingView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
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
            relatedHostingView.update(
                parentController: parentController,
                rootView: BacklinksView(
                    backlinks: state.related,
                    onLink: { [weak self] link in
                        self?.send(.requestLink(link))
                    }
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
                            modified: Date.now,
                            headers: WellKnownHeaders.emptySubtext
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/bar")!,
                            excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                            modified: Date.now,
                            headers: WellKnownHeaders.emptySubtext
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/baz")!,
                            excerpt: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
                            modified: Date.now,
                            headers: WellKnownHeaders.emptySubtext
                        )
                    ]
                )
            )
            return view
        }
    }
}
