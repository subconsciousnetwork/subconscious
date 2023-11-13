//
//  QuoteBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI

extension BlockEditor {
    class ListBlockCell:
        UICollectionViewCell,
        UITextViewDelegate
    {
        static let identifier = "ListBlockCell"
        
        typealias TranscludeListView = BlockEditor.TranscludeListView
        
        var id: UUID = UUID()
        
        weak var delegate: TextBlockDelegate?
        
        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var stackView = UIStackView()
        private var listContainerMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppTheme.unit4,
            bottom: 0,
            trailing: 0
        )
        private lazy var listContainer = UIView()
        private lazy var textView = SubtextTextView()
        private lazy var bulletView = createBulletView()
        private var transcludeMargins = UIEdgeInsets(
            top: AppTheme.unit,
            left: AppTheme.padding,
            bottom: AppTheme.padding,
            right: AppTheme.padding
        )
        
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
            contentView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = 0
            stackView.distribution = .fill
            stackView.alignment = .leading
            stackView.setContentHuggingPriority(
                .defaultHigh,
                for: .vertical
            )
            contentView.addSubview(stackView)
            
            listContainer.directionalLayoutMargins = listContainerMargins
            stackView.addArrangedSubview(listContainer)
            
            textView.isScrollEnabled = false
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self
            textView.inputAccessoryView = toolbar
            listContainer.addSubview(textView)
            
            listContainer.addSubview(bulletView)
            
            transcludeListView.layoutMargins = transcludeMargins
            stackView.addArrangedSubview(transcludeListView)
            stackView.addArrangedSubview(.spacer())

            selectView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(selectView)

            let listContainerGuide = listContainer.layoutMarginsGuide
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
                bulletView.leadingAnchor.constraint(
                    equalTo: listContainer.leadingAnchor,
                    constant: AppTheme.unit4
                ),
                bulletView.topAnchor.constraint(
                    equalTo: listContainer.topAnchor,
                    constant: AppTheme.unit2
                ),
                textView.leadingAnchor.constraint(
                    equalTo: listContainerGuide.leadingAnchor
                ),
                textView.trailingAnchor.constraint(
                    equalTo: listContainerGuide.trailingAnchor
                ),
                textView.topAnchor.constraint(
                    equalTo: listContainerGuide.topAnchor
                ),
                textView.bottomAnchor.constraint(
                    equalTo: listContainerGuide.bottomAnchor
                ),
                stackView.leadingAnchor.constraint(
                    equalTo: leadingAnchor
                ),
                stackView.trailingAnchor.constraint(
                    equalTo: trailingAnchor
                ),
                stackView.topAnchor.constraint(
                    equalTo: topAnchor
                ),
                stackView.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                )
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createBulletView() -> UIView {
            let bulletSize: CGFloat = 6
            let frameWidth: CGFloat = AppTheme.unit2
            let lineHeight: CGFloat = AppTheme.smPfpSize
            
            let frameView = UIView()
            frameView.isUserInteractionEnabled = false
            frameView.translatesAutoresizingMaskIntoConstraints = false
            frameView.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .vertical
            )
            frameView.setContentCompressionResistancePriority(
                .defaultHigh,
                for: .horizontal
            )
            
            let bulletView = UIView()
            bulletView.backgroundColor = .secondaryLabel
            bulletView.translatesAutoresizingMaskIntoConstraints = false
            bulletView.layer.cornerRadius = bulletSize / 2
            frameView.addSubview(bulletView)

            NSLayoutConstraint.activate([
                frameView.widthAnchor.constraint(
                    equalToConstant: frameWidth
                ),
                frameView.heightAnchor.constraint(
                    equalToConstant: lineHeight
                ),
                bulletView.widthAnchor.constraint(
                    equalToConstant: bulletSize
                ),
                bulletView.heightAnchor.constraint(
                    equalToConstant: bulletSize
                ),
                bulletView.centerXAnchor.constraint(
                    equalTo: frameView.centerXAnchor
                ),
                bulletView.centerYAnchor.constraint(
                    equalTo: frameView.centerYAnchor
                )
            ])
            return frameView
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

struct BlockEditorListBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.ListBlockCell()
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
