//
//  QuoteBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class QuoteBlockCell:
        UICollectionViewCell,
        UITextViewDelegate,
        UIViewComponentProtocol
    {
        static let identifier = "QuoteBlockCell"
        
        var id: UUID = UUID()
        
        weak var delegate: TextBlockDelegate?
        
        lazy var textView = SubtextTextView()
        
        private lazy var quoteIndent = createQuoteIndent()
        
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
            
            contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0,
                leading: 20,
                bottom: 0,
                trailing: 0
            )
            
            textView.isScrollEnabled = false
            textView.font = .preferredFont(forTextStyle: .body)
                .italic()
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self
            textView.inputAccessoryView = toolbar
            contentView.addSubview(textView)

            quoteIndent.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(quoteIndent)

            let guide = contentView.layoutMarginsGuide
            NSLayoutConstraint.activate([
                quoteIndent.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 16
                ),
                quoteIndent.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: 8
                ),
                quoteIndent.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -8
                ),
                textView.leadingAnchor.constraint(
                    equalTo: guide.leadingAnchor
                ),
                textView.trailingAnchor.constraint(
                    equalTo: guide.trailingAnchor
                ),
                textView.topAnchor.constraint(
                    equalTo: guide.topAnchor
                ),
                textView.bottomAnchor.constraint(
                    equalTo: guide.bottomAnchor
                )
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createQuoteIndent() -> UIView {
            let view = UIView(frame: .zero)
            view.backgroundColor = .accent
            view.setContentHuggingPriority(
                .fittingSizeLevel,
                for: .vertical
            )
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(
                    equalToConstant: 4
                )
            ])
            return view
        }

        func render(_ state: BlockEditor.TextBlockModel) {
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

struct BlockEditorQuoteBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.QuoteBlockCell()
            view.render(
                BlockEditor.TextBlockModel(
                    text: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."
                )
            )
            return view
        }
    }
}
