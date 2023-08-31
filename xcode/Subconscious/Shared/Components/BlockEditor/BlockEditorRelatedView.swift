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
        private lazy var label = UILabel()
        private lazy var stackView = UIStackView(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            label.text = String(localized: "Related notes")
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            label.numberOfLines = 2
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            
            stackView.axis = .vertical
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: label.topAnchor),
                bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(
            _ state: RelatedModel
        ) {
            stackView.removeAllArrangedSubviews()
            for stub in state.related {
                let transclude = TranscludeView(frame: .zero)
                transclude.render(stub)
                stackView.addArrangedSubview(transclude)
            }
        }
    }
}
