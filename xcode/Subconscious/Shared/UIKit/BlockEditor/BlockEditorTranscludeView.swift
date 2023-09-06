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
        private var margins = NSDirectionalEdgeInsets(
            top: AppTheme.unit3,
            leading: AppTheme.unit4,
            bottom: AppTheme.unit3,
            trailing: AppTheme.unit4
        )
        private var cornerRadius: CGFloat = AppTheme.cornerRadiusLg
        private lazy var stackView = UIStackView()
        private lazy var bylineView = BylineView()
        private lazy var excerptView = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            self.backgroundColor = .tertiarySystemGroupedBackground
            self.layer.cornerRadius = cornerRadius
            self.directionalLayoutMargins = margins
            self.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.addArrangedSubview(bylineView)
            stackView.addArrangedSubview(excerptView)
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(
                    equalTo: layoutMarginsGuide.leadingAnchor
                ),
                stackView.trailingAnchor.constraint(
                    equalTo: layoutMarginsGuide.trailingAnchor
                ),
                stackView.topAnchor.constraint(
                    equalTo: layoutMarginsGuide.topAnchor
                ),
                heightAnchor.constraint(
                    equalTo: stackView.heightAnchor,
                    constant: layoutMargins.top + layoutMargins.bottom
                )
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
