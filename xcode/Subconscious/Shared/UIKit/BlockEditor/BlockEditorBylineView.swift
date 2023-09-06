//
//  BlockEditorBylineView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/5/23.
//

import UIKit

extension BlockEditor {
    struct BylineModel: Hashable {
        var pfp: ProfilePicVariant?
        var slashlink: Slashlink
    }

    class BylineView: UIView, UIRenderableViewProtocol {
        private var height: CGFloat = 22
        private var spacing: CGFloat = 8
        private var stackView = UIStackView()
        private var pfpView = ProfilePicSmView()
        private var slashlinkView = SlashlinkDisplayView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.spacing = spacing
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            addSubview(stackView)
            
            stackView.addArrangedSubview(pfpView)
            stackView.addArrangedSubview(slashlinkView)
            stackView.addArrangedSubview(UIView.spacer())

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                heightAnchor.constraint(equalTo: stackView.heightAnchor)
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
