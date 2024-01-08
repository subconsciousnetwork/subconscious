//
//  TextBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI
import ObservableStore

extension BlockEditor {
    class TextBlockCell:
        UICollectionViewCell,
        UITextViewDelegate
    {
        static let identifier = "TextBlockCell"
        
        typealias TranscludeListView = BlockEditor.TranscludeListView
        
        var id: UUID = UUID()
        
        var send: (TextBlockAction) -> Void = { _ in }
        
        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var stackView = UIStackView()
        private lazy var textView = SubtextTextEditorView(
            send: { [weak self] action in
                self?.send(action)
            }
        )
        private var transcludeListView = UIHostingView<TranscludeListView>()
        
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
            stackView.addArrangedSubview(textView)

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
               
        private func send(
            _ event: SubtextTextEditorAction
        ) {
            self.send(TextBlockAction.from(id: id, action: event))
        }
        
        func update(
            parentController: UIViewController,
            state: BlockEditor.TextBlockModel
        ) {
            self.id = state.id
            transcludeListView.update(
                parentController: parentController,
                entries: state.transcludes,
                send: Address.forward(send: send, tag: TextBlockAction.from)
            )
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
    }
}

struct BlockEditorTextBlockCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = BlockEditor.TextBlockCell()
            let controller = UIViewController()
            view.update(
                parentController: controller,
                state: BlockEditor.TextBlockModel(
                    dom: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
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
            let controller = UIViewController()
            view.update(
                parentController: controller,
                state: BlockEditor.TextBlockModel(
                    dom: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
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
