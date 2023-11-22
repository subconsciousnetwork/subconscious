//
//  HeadingBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class HeadingBlockCell:
        UICollectionViewCell,
        UITextViewDelegate
    {
        static let identifier = "HeadingBlockCell"
        
        var id: UUID = UUID()
        
        var send: (TextBlockAction) -> Void = { _ in }

        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var textView = SubtextTextEditorView(
            send: { [weak self] action in
                self?.send(action)
            }
        )
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .systemBackground
            
            // Automatically adjust font size based on system font size
            textView.isScrollEnabled = false
            textView.font = .preferredFont(forTextStyle: .headline)
            textView.adjustsFontForContentSizeCategory = true
            textView.textContainerInset = UIEdgeInsets(
                top: AppTheme.unit2,
                left: AppTheme.padding,
                bottom: AppTheme.unit2,
                right: AppTheme.padding
            )
            textView.textContainer.lineFragmentPadding = 0
            textView.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            contentView.addSubview(textView)

            selectView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(selectView)

            NSLayoutConstraint.activate([
                selectView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: AppTheme.unit
                ),
                selectView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -1 * AppTheme.unit
                ),
                selectView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                selectView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                ),
                textView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                textView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                textView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                textView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                )
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(_ state: BlockEditor.TextBlockModel) {
            self.id = state.id
            if textView.text != state.text {
                textView.text = state.text
            }
            if textView.selectedRange != state.selection {
                textView.selectedRange = state.selection
            }
            textView.setFirstResponder(state.isEditing)
            // Set editability of textview
            textView.setModifiable(!state.isBlockSelectMode)
            // Handle select mode
            selectView.isHidden = !state.isBlockSelected
        }
        
        private func send(
            _ event: UIView.SubtextTextEditorView.Action
        ) {
            self.send(TextBlockAction.from(id: id, action: event))
        }
    }
}

struct BlockEditorHeadingBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.HeadingBlockCell()
            view.update(
                BlockEditor.TextBlockModel(
                    text: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."
                )
            )
            return view
        }
    }
}
