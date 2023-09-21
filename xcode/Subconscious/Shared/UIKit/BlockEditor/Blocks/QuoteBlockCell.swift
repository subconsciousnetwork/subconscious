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
        
        private lazy var stackView = UIStackView()
        private lazy var textView = SubtextTextView()
        private var quoteContainerMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppTheme.unit4,
            bottom: 0,
            trailing: 0
        )
        private lazy var quoteContainer = UIView()
        private lazy var quoteBar = createQuoteBar()
        private var transcludeMargins = NSDirectionalEdgeInsets(
            top: AppTheme.unit,
            leading: AppTheme.padding,
            bottom: AppTheme.padding,
            trailing: AppTheme.padding
        )
        private lazy var transcludeListView = BlockEditor.TranscludeListView()
        
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
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            contentView.addSubview(stackView)
            
            quoteContainer.directionalLayoutMargins = quoteContainerMargins
            quoteContainer.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            quoteContainer.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            stackView.addArrangedSubview(quoteContainer)
            
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.isScrollEnabled = false
            textView.delegate = self
            textView.inputAccessoryView = toolbar
            quoteContainer.addSubview(textView)
            
            quoteContainer.addSubview(quoteBar)
            
            transcludeListView.directionalLayoutMargins = transcludeMargins
            stackView.addArrangedSubview(transcludeListView)

            let quoteContainerGuide = quoteContainer.layoutMarginsGuide
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(
                    equalTo: quoteContainerGuide.leadingAnchor
                ),
                textView.trailingAnchor.constraint(
                    equalTo: quoteContainerGuide.trailingAnchor
                ),
                textView.topAnchor.constraint(
                    equalTo: quoteContainerGuide.topAnchor
                ),
                textView.bottomAnchor.constraint(
                    equalTo: quoteContainerGuide.bottomAnchor
                ),
                quoteBar.leadingAnchor.constraint(
                    equalTo: quoteContainer.leadingAnchor,
                    constant: AppTheme.unit4
                ),
                quoteBar.topAnchor.constraint(
                    equalTo: quoteContainerGuide.topAnchor
                ),
                quoteBar.bottomAnchor.constraint(
                    equalTo: quoteContainerGuide.bottomAnchor
                ),
                stackView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                stackView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                stackView.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                stackView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                )
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createQuoteBar() -> UIView {
            let quoteFrameView = UIView()
            quoteFrameView.translatesAutoresizingMaskIntoConstraints = false

            let quoteView = UIView()
            quoteView.translatesAutoresizingMaskIntoConstraints = false
            quoteView.backgroundColor = .accent
            quoteView.setContentHuggingPriority(
                .fittingSizeLevel,
                for: .vertical
            )
            quoteFrameView.addSubview(quoteView)
            
            NSLayoutConstraint.activate([
                quoteFrameView.widthAnchor.constraint(
                    equalToConstant: AppTheme.unit2
                ),
                quoteView.widthAnchor.constraint(
                    equalToConstant: 2
                ),
                quoteView.centerXAnchor.constraint(
                    equalTo: quoteFrameView.centerXAnchor
                ),
                quoteView.topAnchor.constraint(
                    equalTo: quoteFrameView.topAnchor,
                    constant: AppTheme.unit2
                ),
                quoteView.bottomAnchor.constraint(
                    equalTo: quoteFrameView.bottomAnchor,
                    constant: -1 * AppTheme.unit2
                )
            ])
            return quoteFrameView
        }

        func render(_ state: BlockEditor.TextBlockModel) {
            self.id = state.id
            transcludeListView.render(state.transcludes)
            // Hide view if there are no transcludes
            transcludeListView.isHidden = state.transcludes.count < 1
            if textView.text != state.text {
                textView.text = state.text
            }
            if textView.selectedRange != state.selection {
                textView.selectedRange = state.selection
            }
            textView.setFirstResponder(state.isEditing)
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
                    text: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled.",
                    transcludes: [
                        EntryStub(
                            address: Slashlink("@example/foo")!,
                            excerpt: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization.",
                            modified: Date.now,
                            author: nil
                        ),
                        EntryStub(
                            address: Slashlink("@example/bar")!,
                            excerpt: "Modularity is a form of hierarchy",
                            modified: Date.now,
                            author: nil
                        ),
                    ]
                )
            )
            return view
        }
    }
}
