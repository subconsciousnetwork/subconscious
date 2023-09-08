//
//  BlockEditorRelatedView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class RelatedView: UIView, UIViewComponentProtocol {
        var id = UUID()
        private var labelHeight: CGFloat = 16
        private var labelInsets = UIEdgeInsets(
            top: 0,
            left: 16,
            bottom: 0,
            right: 16
        )
        private var bodySpacing: CGFloat = 8
        private var transcludeSpacing: CGFloat = 8
        private lazy var headingView = BlockEditor.AppendixHeadingView()
        private lazy var bodyView = UIStackView(frame: .zero)
        private lazy var transcludesView = UIStackView(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)
            setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            bodyView.axis = .vertical
            bodyView.spacing = bodySpacing
            bodyView.distribution = .fill
            bodyView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            bodyView.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            bodyView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bodyView)
            
            headingView.render(String(localized: "Related notes"))
            headingView.translatesAutoresizingMaskIntoConstraints = false
            bodyView.addArrangedSubview(headingView)
            
            transcludesView.axis = .vertical
            transcludesView.translatesAutoresizingMaskIntoConstraints = false
            transcludesView.spacing = transcludeSpacing
            bodyView.addArrangedSubview(transcludesView)
            
            NSLayoutConstraint.activate([
                bodyView.leadingAnchor.constraint(equalTo: leadingAnchor),
                bodyView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bodyView.topAnchor.constraint(equalTo: topAnchor),
                bodyView.bottomAnchor.constraint(equalTo: bottomAnchor)
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
