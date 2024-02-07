//
//  QuoteBlockCell.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/20/23.
//

import UIKit
import SwiftUI
import ObservableStore

extension BlockEditor {
    class ListBlockCell:
        UICollectionViewCell,
        UITextViewDelegate,
        BlockCellProtocol
    {
        static let identifier = "ListBlockCell"
        
        typealias TranscludeListView = BlockEditor.TranscludeListView
        
        var id: UUID = UUID()
        
        var send: (TextBlockAction) -> Void = { _ in }

        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var stackView = UIStackView().vStack()
        private lazy var listContainer = UIView()
        private lazy var textView = SubtextTextEditorView(
            send: { [weak self] action in
                self?.send(action)
            }
        )
        private lazy var bulletView = createBulletView()
        private var transcludeListView = UIHostingView<TranscludeListView>()
        
        override init(frame: CGRect) {
            super.init(frame: frame)

            self.themeDefault()

            contentView
                .layoutBlock()
                .addingSubview(selectView) { selectView in
                    selectView.layoutDefault()
                }
                .addingSubview(stackView) { stackView in
                    listContainer
                        .addingSubview(textView) { textView in
                            textView.layoutBlock(
                                edges: UIEdgeInsets(
                                    top: 0,
                                    left: AppTheme.unit4,
                                    bottom: 0,
                                    right: 0
                                )
                            )
                        }
                        .addingSubview(bulletView) { bulletView in
                            bulletView
                                .anchorLeading(constant: AppTheme.unit4)
                                .anchorTop(constant: AppTheme.unit2)
                        }

                    stackView
                        .layoutBlock()
                        .addingArrangedSubview(listContainer)
                        .addingArrangedSubview(transcludeListView)
                }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func createBulletView() -> UIView {
            let bulletSize: CGFloat = 6
            let frameWidth: CGFloat = AppTheme.unit2
            let lineHeight: CGFloat = AppTheme.lineHeight
            
            let frameView = UIView()
                .setting(\.isUserInteractionEnabled, value: false)
                .contentCompressionResistance(for: .vertical)
                .contentCompressionResistance(for: .horizontal)
                .anchorWidth(constant: frameWidth)
                .anchorHeight(constant: lineHeight)
                .addingSubview(UIView()) { bulletView in
                    bulletView.backgroundColor = .secondaryLabel
                    let halfBulletSize = bulletSize / 2
                    bulletView.layer.cornerRadius = halfBulletSize
                    bulletView
                        .anchorWidth(constant: bulletSize)
                        .anchorHeight(constant: bulletSize)
                        .anchorCenterY(constant: -1 * halfBulletSize)
                        .anchorCenterX()
                }

            return frameView
        }

        func update(
            parentController: UIViewController,
            state: BlockEditor.BlockModel
        ) {
            self.id = state.id
            transcludeListView.update(
                parentController: parentController,
                entries: state.body.transcludes,
                send: Address.forward(
                    send: send,
                    tag: BlockEditor.TextBlockAction.from
                )
            )
            textView.setText(
                state.body.dom.description,
                selectedRange: state.body.textSelection
            )
            textView.setFirstResponder(state.body.blockSelection.isEditing)
            // Set editability of textview
            textView.setModifiable(!state.body.blockSelection.isBlockSelectMode)
            // Handle block select mode
            selectView.update(state.body.blockSelection)
        }

        private func send(
            _ event: SubtextTextEditorAction
        ) {
            self.send(
                BlockEditor.TextBlockAction.from(
                    id: id,
                    action: event
                )
            )
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
                state: BlockEditor.BlockModel(
                    body: BlockEditor.BlockBodyModel(
                        dom: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
                        transcludes: [
                            EntryStub(
                                did: Did("did:key:abc123")!,
                                address: Slashlink("@example/foo")!,
                                excerpt: Subtext(markup: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization."),
                                headers: .emptySubtext
                            ),
                            EntryStub(
                                did: Did("did:key:abc123")!,
                                address: Slashlink("@example/bar")!,
                                excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                                headers: .emptySubtext
                            ),
                        ]
                    )
                )
            )
            return view
        }
    }
}
