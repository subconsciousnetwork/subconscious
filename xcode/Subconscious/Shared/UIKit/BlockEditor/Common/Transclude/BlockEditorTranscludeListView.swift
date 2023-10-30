//
//  BlockEditorTranscludeListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/8/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class TranscludeListView: UIView, UIViewRenderableProtocol {
        private var transcludeSpacing: CGFloat = 8
        private var stackView = UIStackView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)

            setContentHuggingPriority(.defaultHigh, for: .vertical)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = transcludeSpacing
            stackView.alignment = .fill
            stackView.distribution = .fill
            stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            
            addSubview(stackView)

            let guide = layoutMarginsGuide
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(
                    equalTo: guide.leadingAnchor
                ),
                stackView.trailingAnchor.constraint(
                    equalTo: guide.trailingAnchor
                ),
                stackView.topAnchor.constraint(
                    equalTo: guide.topAnchor
                ),
                stackView.bottomAnchor.constraint(
                    equalTo: guide.bottomAnchor
                ),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(_ state: [EntryStub]) {
            stackView.removeAllArrangedSubviewsCompletely()
            for stub in state {
                let transclude = BlockEditor.TranscludeView()
                stackView.addArrangedSubview(transclude)
                transclude.render(stub)
            }
        }
    }
}

struct BlockEditorTranscludeListView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.TranscludeListView()
            view.render(
                [
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
                        isTruncated: false,
                        modified: Date.now
                    )
                ]
            )
            return view
        }
    }
}
