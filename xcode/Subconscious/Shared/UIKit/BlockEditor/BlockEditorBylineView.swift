//
//  BlockEditorBylineView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/5/23.
//

import UIKit

extension BlockEditor {
    struct BylineModel: Hashable {
        var pfp: ProfilePicVariant
        var slashlink: Slashlink
    }

    class BylineView: UIView, UIRenderableViewProtocol {
        private var height: CGFloat = 22
        private var stackView = UIStackView()
        private var pfpView = ProfilePicSmView()
        private var slashlinkView = SlashlinkDisplayView(frame: .zero)
        
        override init(frame: CGRect) {
            super.init(frame: frame)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)

            stackView.addArrangedSubview(pfpView)
            stackView.addArrangedSubview(slashlinkView)

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

        func render(_ state: BylineModel) {
            pfpView.render(state.pfp)
            slashlinkView.render(state.slashlink)
        }
    }
}
