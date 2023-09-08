//
//  QuoteBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit

extension BlockEditor {
    class ListBlockCell:
        UICollectionViewCell,
        UITextViewDelegate,
        UIViewComponentProtocol
    {
        static let identifier = "ListBlockCell"
        
        var id: UUID = UUID()
        
        weak var delegate: TextBlockDelegate?
        
        private lazy var textView = SubtextTextView()
        private lazy var bullet = createBullet()
        
        private lazy var toolbar = UIToolbar.blockToolbar(
            upButtonPressed: { [weak self] in
                guard let self = self else { return }
                self.delegate?.upButtonPressed(id: self.id)
            },
            downButtonPressed: { [weak self] in
                guard let self = self else { return }
                self.delegate?.downButtonPressed(id: self.id)
            },
            boldButtonPressed: { [weak self] in
                guard let self = self else { return }
                self.delegate?.boldButtonPressed(
                    id: self.id,
                    text: self.textView.text,
                    selection: self.textView.selectedRange
                )
            },
            italicButtonPressed: { [weak self] in
                guard let self = self else { return }
                self.delegate?.italicButtonPressed(
                    id: self.id,
                    text: self.textView.text,
                    selection: self.textView.selectedRange
                )
            },
            codeButtonPressed: { [weak self] in
                guard let self = self else { return }
                self.delegate?.codeButtonPressed(
                    id: self.id,
                    text: self.textView.text,
                    selection: self.textView.selectedRange
                )
            },
            dismissKeyboardButtonPressed: { [weak self] in
                guard let self = self else { return }
                self.delegate?.dismissKeyboardButtonPressed(id: self.id)
            }
        )
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            
            textView.isScrollEnabled = false
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self
            textView.inputAccessoryView = toolbar
            contentView.addSubview(textView)
                        
            NSLayoutConstraint.activate([
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
        
        private func createBullet() -> UIView {
            let view = UIView(frame: .zero)
            view.backgroundColor = .secondaryLabel
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 4
            return view
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
    }
}
