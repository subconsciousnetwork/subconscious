//
//  TextBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class TextBlockCell:
        UICollectionViewCell,
        UITextViewDelegate,
        UIViewComponentProtocol
    {
        static let identifier = "TextBlockCell"
        
        var id: UUID = UUID()
        
        weak var delegate: TextBlockDelegate?
        
        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var stackView = UIStackView()
        private lazy var textView = SubtextTextView()
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
            
            contentView.backgroundColor = .systemBackground
            contentView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = AppTheme.unit
            stackView.alignment = .fill
            stackView.distribution = .fill
            stackView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            contentView.addSubview(stackView)
            
            textView.isEditable = true
            textView.isScrollEnabled = false
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self
            textView.inputAccessoryView = toolbar
            stackView.addArrangedSubview(textView)

            transcludeListView.directionalLayoutMargins = transcludeMargins
            stackView.addArrangedSubview(transcludeListView)
            
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
        
        override func prepareForReuse() {
            self.render(BlockEditor.TextBlockModel())
        }
        
        func render(_ state: BlockEditor.TextBlockModel) {
            self.id = state.id
            transcludeListView.render(state.transcludes)
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

struct BlockEditorTextBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.TextBlockCell()
            view.render(
                BlockEditor.TextBlockModel(
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
                            isTruncated: true,
                            modified: Date.now
                        ),
                    ]
                )
            )
            return view
        }

        UIViewPreviewRepresentable {
            let view = BlockEditor.TextBlockCell()
            view.render(
                BlockEditor.TextBlockModel(
                    text: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled.",
                    isBlockSelectMode: true,
                    isBlockSelected: true,
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
