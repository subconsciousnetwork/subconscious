//
//  BlockEditorRelatedView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit

extension BlockEditor {
    class RelatedView: UIView, Identifiable {
        var id = UUID()
        private lazy var stackView = UIStackView(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)
            stackView.axis = .vertical
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                self.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(
            _ related: RelatedModel
        ) {
            stackView.removeAllArrangedSubviews()
        }
    }
}
