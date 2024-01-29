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
        private lazy var stackView = UIStackView().vStack()
        private lazy var textView = SubtextTextEditorView(
            send: { [weak self] action in
                self?.send(action)
            }
        )
        private var transcludeListView = UIHostingView<TranscludeListView>()
        private lazy var dividerView = UIView.divider()

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView
                .setting(\.backgroundColor, value: .systemBackground)
                .layoutBlock()
                .addingSubview(stackView) { stackView in
                    stackView
                        .layoutBlock()
                        .addingArrangedSubview(self.dividerView)
                        .addingArrangedSubview(self.textView)
                        .addingArrangedSubview(self.transcludeListView)
                }
                .addingSubview(selectView) { selectView in
                    selectView.defaultLayout()
                }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
               
        private func send(
            _ event: SubtextTextEditorAction
        ) {
            self.send(BlockEditor.TextBlockAction.from(id: id, action: event))
        }
        
        func update(
            parentController: UIViewController,
            state: BlockEditor.TextBlockModel
        ) {
            self.id = state.id
            transcludeListView.update(
                parentController: parentController,
                entries: state.transcludes,
                send: Address.forward(
                    send: send,
                    tag: BlockEditor.TextBlockAction.from
                )
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
