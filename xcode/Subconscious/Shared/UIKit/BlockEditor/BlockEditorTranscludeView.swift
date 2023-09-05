//
//  BlockEditorTranscludeView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit

extension BlockEditor {
    class TranscludeView: UIView, UIComponentViewProtocol {
        var id = UUID()
        private lazy var stackView = UIStackView(frame: .zero)
        private lazy var bylineView = BylineView(frame: .zero)
        private lazy var excerptView = UILabel(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.addArrangedSubview(bylineView)
            stackView.addArrangedSubview(excerptView)
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(
            _ stub: EntryStub
        ) {
            bylineView.render(
                BylineModel(
                    pfp: stub.author?.pfp,
                    slashlink: stub.address
                )
            )
            self.excerptView.text = stub.excerpt
        }
    }
}
