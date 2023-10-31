//
//  HeadingBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI

protocol HeadingBlockCellDelegate:
    BlockControlsDelegate &
    BlockTextEditingDelegate
{

}

extension BlockEditor {
    class HeadingBlockCell:
        UICollectionViewCell,
        UITextViewDelegate,
        UIViewComponentProtocol
    {
        static let identifier = "HeadingBlockCell"
        
        var id: UUID = UUID()
        
        weak var delegate: HeadingBlockCellDelegate?
        
        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var textView = UITextView(frame: .zero)
        
        private lazy var toolbar = self.createToolbar()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .systemBackground
            
            // Automatically adjust font size based on system font size
            textView.isScrollEnabled = false
            textView.font = .preferredFont(forTextStyle: .headline)
            textView.adjustsFontForContentSizeCategory = true
            textView.textContainerInset = UIEdgeInsets(
                top: 8,
                left: 16,
                bottom: 8,
                right: 16
            )
            textView.textContainer.lineFragmentPadding = 0
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self
            textView.inputAccessoryView = toolbar
            
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
        
        func render(_ state: BlockEditor.TextBlockModel) {
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
        
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            // Enter/newline
            if text == "\n" {
                self.delegate?.requestSplit(
                    id: self.id,
                    selection: self.textView.selectedRange
                )
                return false
            }
            // Hit delete while cursor was at beginning of block
            else if range.length == 0 && text.isEmpty {
                self.delegate?.requestMerge(id: self.id)
                return false
            }
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            UIView.performWithoutAnimation {
                self.invalidateIntrinsicContentSize()
            }
            delegate?.didChange(
                id: self.id,
                text: self.textView.text,
                selection: self.textView.selectedRange
            )
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            delegate?.didChangeSelection(
                id: self.id,
                selection: self.textView.selectedRange
            )
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            delegate?.didBeginEditing(id: self.id)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            delegate?.didEndEditing(id: self.id)
        }

        private func createToolbar() -> UIToolbar {
            let toolbar = UIToolbar()

            let upButton = UIBarButtonItem(
                title: String(localized: "Move block up"),
                image: UIImage(systemName: "chevron.up"),
                handle: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.upButtonPressed(id: self.id)
                }
            )

            let downButton = UIBarButtonItem(
                title: String(localized: "Move block down"),
                image: UIImage(systemName: "chevron.down"),
                handle: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.downButtonPressed(id: self.id)
                }
            )

            let spacer = UIBarButtonItem.flexibleSpace()
            
            let dismissKeyboardButton = UIBarButtonItem(
                title: String(localized: "Dismiss keyboard"),
                image: UIImage(systemName: "keyboard.chevron.compact.down"),
                handle: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.dismissKeyboardButtonPressed(id: self.id)
                }
            )

            toolbar.setItems(
                [
                    upButton,
                    downButton,
                    spacer,
                    dismissKeyboardButton
                ],
                animated: false
            )
            toolbar.isTranslucent = false
            toolbar.sizeToFit()
            return toolbar
        }
    }
}

struct BlockEditorHeadingBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.HeadingBlockCell()
            view.render(
                BlockEditor.TextBlockModel(
                    text: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."
                )
            )
            return view
        }
    }
}
