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
        UITextViewDelegate
    {
        static let identifier = "QuoteBlockCell"
        
        typealias TranscludeListView = BlockEditor.TranscludeListView

        var id: UUID = UUID()
        
        weak var delegate: TextBlockDelegate?
        
        private lazy var selectView = BlockEditor.BlockSelectView()
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
        private var transcludeListView = UIHostingView<TranscludeListView>()
        
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
            
            stackView.addArrangedSubview(transcludeListView)
            stackView.addArrangedSubview(.spacer())

            selectView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(selectView)

            let quoteContainerGuide = quoteContainer.layoutMarginsGuide
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

        func update(
            parentController: UIViewController,
            state: BlockEditor.TextBlockModel
        ) {
            self.id = state.id
            transcludeListView.update(
                parentController: parentController,
                rootView: TranscludeListView(
                    entries: state.transcludes,
                    onViewTransclude: { _ in },
                    onTranscludeLink: { _, _ in }
                )
            )
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
    }
}

struct BlockEditorQuoteBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.QuoteBlockCell()
            let controller = UIViewController()
            view.update(
                parentController: controller,
                state: BlockEditor.TextBlockModel(
                    text: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled.",
                    transcludes: [
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/foo")!,
                            excerpt: Subtext(markup: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization."),
                            isTruncated: true,
                            modified: Date.now
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/bar")!,
                            excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                            isTruncated: false,
                            modified: Date.now
                        ),
                    ]
                )
            )
            return view
        }
    }
}
