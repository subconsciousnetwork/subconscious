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

        private lazy var stackView = UIStackView().vStack()
        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var textView = SubtextTextEditorView(
            send: { [weak self] action in
                self?.send(action)
            }
        )
        private lazy var dividerView = UIView.divider()

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .systemBackground
            
            textView.modifier({ textView in
                textView.font = .preferredFont(forTextStyle: .headline)
                textView.textContainerInset = UIEdgeInsets(
                    top: AppTheme.unit2,
                    left: AppTheme.padding,
                    bottom: AppTheme.unit2,
                    right: AppTheme.padding
                )
                textView.textContainer.lineFragmentPadding = 0
            })

            contentView
                .layoutBlock()
                .addingSubview(stackView) { stackView in
                    stackView
                        .layoutBlock()
                        .addingArrangedSubview(self.dividerView)
                        .addingArrangedSubview(self.textView)
                }
                .addingSubview(selectView) { selectView in
                    selectView.defaultLayout()
                }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(_ state: BlockEditor.TextBlockModel) {
            self.id = state.id
            textView.setText(
                state.dom.description,
                selectedRange: state.selection
            )
            textView.setFirstResponder(state.isEditing)
            // Set editability of textview
            textView.setModifiable(!state.isBlockSelectMode)
            // Handle block select mode
            selectView.setSelectedState(state.isBlockSelected)
        }

        private func send(
            _ event: SubtextTextEditorAction
        ) {
            self.send(BlockEditor.TextBlockAction.from(id: id, action: event))
        }
    }
}

struct BlockEditorHeadingBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.HeadingBlockCell()
            view.update(
                BlockEditor.TextBlockModel(
                    dom: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled.")
                )
            )
            return view
        }
    }
}
