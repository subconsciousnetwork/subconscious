//
//  HeadingBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit

protocol HeadingBlockCellDelegate:
    BlockControlsDelegate &
    BlockTextEditingDelegate
{

}

extension BlockEditor {
    class HeadingBlockCell:
        UICollectionViewCell,
        UITextViewDelegate,
        Identifiable
    {
        static let identifier = "HeadingBlockCell"
        
        var id: UUID = UUID()
        
        weak var delegate: HeadingBlockCellDelegate?
        
        lazy var textView = UITextView(frame: .zero)
        
        private lazy var divider = UIView.divider()
        
        private lazy var toolbar = self.createToolbar()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .systemBackground
            
            // Automatically adjust font size based on system font size
            textView.adjustsFontForContentSizeCategory = true
            textView.backgroundColor = .systemBackground
            textView.isScrollEnabled = false
            textView.textContainerInset = UIEdgeInsets(
                top: 12,
                left: 12,
                bottom: 12,
                right: 12
            )
            textView.font = .preferredFont(forTextStyle: .headline)
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self
            
            textView.inputAccessoryView = toolbar
            
            addSubview(textView)
            addSubview(divider)

            NSLayoutConstraint.activate([
                textView.widthAnchor.constraint(equalToConstant: frame.width),
                textView.topAnchor.constraint(equalTo: topAnchor),
                
                divider.topAnchor.constraint(equalTo: textView.bottomAnchor),
                divider.leadingAnchor.constraint(equalTo: leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: trailingAnchor),
                
                bottomAnchor.constraint(equalTo: divider.bottomAnchor),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func render(_ state: TextBlockModel) {
            self.id = state.id
            if textView.text != state.text {
                textView.text = state.text
            }
            if textView.selectedRange != state.selection {
                textView.selectedRange = state.selection
            }
            textView.setFirstResponder(state.isFocused)
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