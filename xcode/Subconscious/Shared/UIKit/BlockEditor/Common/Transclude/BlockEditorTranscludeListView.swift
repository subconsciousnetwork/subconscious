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

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(_ state: [EntryStub]) {
            stackView.removeAllArrangedSubviews()
            for stub in state {
                let transclude = BlockEditor.TranscludeView()
                transclude.render(stub)
                stackView.addArrangedSubview(transclude)
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
            return view
        }
    }
}
