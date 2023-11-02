//
//  BlockEditorBylineView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/5/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    struct BylineModel: Hashable {
        var pfp: ProfilePicVariant?
        var slashlink: Slashlink
    }

    class BylineView: UIView, UIViewRenderableProtocol {
        private var height: CGFloat = AppTheme.smPfpSize
        private var spacing: CGFloat = AppTheme.unit2
        private var stackView = UIStackView()
        private var pfpView = ProfilePicSmView()
        private var slashlinkView = SlashlinkDisplayView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.spacing = spacing
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            stackView.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            addSubview(stackView)
            
            stackView.addArrangedSubview(pfpView)
            stackView.addArrangedSubview(slashlinkView)
            stackView.addArrangedSubview(UIView.spacer())
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                heightAnchor.constraint(equalToConstant: height)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(_ state: BlockEditor.BylineModel) {
            pfpView.render(state.pfp)
            slashlinkView.render(state.slashlink)
        }
    }
}

struct BlockEditorBylineView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.BylineView()
            view.render(
                BlockEditor.BylineModel(
                    slashlink: Slashlink(
                        petname: Petname("name"),
                        slug: Slug("place-with-a-very-long-name-to-test-wrapping-behavior-of-the-view")!
                    )
                )
            )
            return view
        }
    }
}
