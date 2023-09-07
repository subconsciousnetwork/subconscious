//
//  BlockEditorAppendixHeadingView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/7/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class AppendixHeadingView: UIView, UIViewRenderableProtocol {
        private var insets = NSDirectionalEdgeInsets(
            top: 20,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
        private var labelHeight: CGFloat = 16
        private var labelView = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            directionalLayoutMargins = insets
            
            labelView.translatesAutoresizingMaskIntoConstraints = false
            labelView.numberOfLines = 1
            labelView.font = UIFont.preferredFont(forTextStyle: .caption2)
            setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            addSubview(labelView)
            
            NSLayoutConstraint.activate([
                heightAnchor.constraint(
                    equalToConstant: (
                        labelHeight +
                        layoutMargins.top +
                        layoutMargins.bottom
                    )
                ),
                labelView.heightAnchor.constraint(
                    equalToConstant: labelHeight
                ),
                labelView.topAnchor.constraint(
                    equalTo: layoutMarginsGuide.topAnchor
                ),
                labelView.leadingAnchor.constraint(
                    equalTo: layoutMarginsGuide.leadingAnchor
                ),
                labelView.trailingAnchor.constraint(
                    equalTo: layoutMarginsGuide.trailingAnchor
                ),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(_ text: String) {
            self.labelView.text = text
        }
    }
}

struct BlockEditorAppendixHeadingView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.AppendixHeadingView()
            view.render("Example text")
            return view
        }
    }
}
