//
//  BlockEditorTranscludeView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/31/23.
//

import UIKit
import SwiftUI

protocol BlockEditorTranscludeDelegate: AnyObject {
    func onTap(_ view: BlockEditor.TranscludeView)
}

extension BlockEditor {
    class TranscludeView: UIView, UIViewComponentProtocol {
        var id = UUID()
        var delegate: BlockEditorTranscludeDelegate?
        private var margins = NSDirectionalEdgeInsets(
            top: AppTheme.unit3,
            leading: AppTheme.unit4,
            bottom: AppTheme.unit3,
            trailing: AppTheme.unit4
        )
        private var cornerRadius: CGFloat = AppTheme.cornerRadiusLg
        private var stackSpacing = AppTheme.unit
        private lazy var stackView = UIStackView()
        private lazy var bylineView = BylineView()
        private lazy var excerptView = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .tertiarySystemGroupedBackground
            layer.cornerRadius = cornerRadius
            directionalLayoutMargins = margins
            setContentHuggingPriority(.defaultHigh, for: .vertical)

            let tapGesture = UITapGestureRecognizer(
                target: self,
                action: #selector(onTap)
            )
            self.addGestureRecognizer(tapGesture)
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.spacing = stackSpacing
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            addSubview(stackView)

            stackView.addArrangedSubview(bylineView)

            // A very large, but finite number of lines
            excerptView.numberOfLines = 50
            excerptView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            stackView.addArrangedSubview(excerptView)
            
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
                stackView.bottomAnchor.constraint(
                    equalTo: layoutMarginsGuide.bottomAnchor
                )
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func onTap(sender: UITapGestureRecognizer) {
            self.delegate?.onTap(self)
        }

        override func touchesBegan(
            _ touches: Set<UITouch>,
            with event: UIEvent?
        ) {
            super.touchesBegan(touches, with: event)
            next?.touchesBegan(touches, with: event)
            self.backgroundColor = .secondarySystemGroupedBackground
        }
        
        override func touchesCancelled(
            _ touches: Set<UITouch>,
            with event: UIEvent?
        ) {
            super.touchesCancelled(touches, with: event)
            next?.touchesCancelled(touches, with: event)
            self.backgroundColor = .tertiarySystemGroupedBackground
        }

        override func touchesEnded(
            _ touches: Set<UITouch>,
            with event: UIEvent?
        ) {
            super.touchesEnded(touches, with: event)
            next?.touchesEnded(touches, with: event)
            self.backgroundColor = .tertiarySystemGroupedBackground
        }

        func render(
            _ stub: EntryStub
        ) {
            bylineView.render(
                BlockEditor.BylineModel(
                    pfp: stub.author?.pfp,
                    slashlink: stub.address
                )
            )
            self.excerptView.text = stub.excerpt
        }
    }
}

struct BlockEditorTranscludeView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.TranscludeView()
            view.render(
                EntryStub(
                    address: Slashlink("@example/foo")!,
                    excerpt: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization.",
                    modified: Date.now,
                    author: nil
                )
            )
            return view
        }
    }
}
