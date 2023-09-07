//
//  BlockEditorRelatedView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class RelatedView: UIView, UIComponentViewProtocol {
        var id = UUID()
        private var bodySpacing: CGFloat = 8
        private var transcludeSpacing: CGFloat = 8
        private lazy var label = UILabel()
        private lazy var bodyView = UIStackView(frame: .zero)
        private lazy var transcludesView = UIStackView(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            bodyView.axis = .vertical
            bodyView.spacing = bodySpacing
            bodyView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bodyView)
            
            label.text = String(localized: "Related notes")
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            label.numberOfLines = 2
            label.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            label.translatesAutoresizingMaskIntoConstraints = false
            bodyView.addArrangedSubview(label)
            
            transcludesView.axis = .vertical
            transcludesView.translatesAutoresizingMaskIntoConstraints = false
            transcludesView.spacing = transcludeSpacing
            bodyView.addArrangedSubview(transcludesView)
            
            NSLayoutConstraint.activate([
                bodyView.leadingAnchor.constraint(equalTo: leadingAnchor),
                bodyView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bodyView.topAnchor.constraint(equalTo: topAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(
            _ state: BlockEditor.RelatedModel
        ) {
            transcludesView.removeAllArrangedSubviews()
            for stub in state.related {
                let transclude = BlockEditor.TranscludeView()
                transclude.render(stub)
                transclude.translatesAutoresizingMaskIntoConstraints = false
                transcludesView.addArrangedSubview(transclude)
            }
        }
    }
}

struct BlockEditorRelatedView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let related = BlockEditor.RelatedView()
            related.render(
                BlockEditor.RelatedModel(
                    related: [
                        EntryStub(
                            address: Slashlink("@example/foo")!,
                            excerpt: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization.",
                            modified: Date.now,
                            author: nil
                        ),
                        EntryStub(
                            address: Slashlink("@example/bar")!,
                            excerpt: "Modularity is a form of hierarchy",
                            modified: Date.now,
                            author: nil
                        ),
                        EntryStub(
                            address: Slashlink("@example/baz")!,
                            excerpt: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled.",
                            modified: Date.now,
                            author: nil
                        )
                    ]
                )
            )
            return related
        }
    }
}
