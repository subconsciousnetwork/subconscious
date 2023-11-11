//
//  BlockEditorSlashlinkDisplayView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/5/23.
//

import UIKit

extension BlockEditor {
    class SlashlinkDisplayView: UIView {
        private var height: CGFloat = AppTheme.smPfpSize
        private var stackView = UIStackView(frame: .zero)
        private var petnameView = UILabel(frame: .zero)
        private var slugView = UILabel(frame: .zero)

        override init(frame: CGRect) {
            super.init(frame: frame)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.alignment = .center
            addSubview(stackView)
            
            petnameView.textColor = .accent
            petnameView.font = .preferredFont(forTextStyle: .body).bold()
            stackView.addArrangedSubview(petnameView)

            slugView.textColor = .secondaryLabel
            slugView.font = .preferredFont(forTextStyle: .body)
            stackView.addArrangedSubview(slugView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(_ slashlink: Slashlink) {
            petnameView.text = slashlink.petname?.markup
            slugView.text = slashlink.slug.markup
        }
    }
}
