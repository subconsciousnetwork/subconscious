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
    class QuoteBlockCell:
        UICollectionViewCell,
        UITextViewDelegate
    {
        static let identifier = "QuoteBlockCell"
        
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
        private var quoteContainerMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppTheme.unit4,
            bottom: 0,
            trailing: 0
        )
        private lazy var quoteContainer = UIView()
        private lazy var quoteBar = createQuoteBar()
        private var transcludeListView = UIHostingView<TranscludeListView>()

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
            quoteContainer.addSubview(textView)
            
            quoteContainer.addSubview(quoteBar)
            
            stackView.addArrangedSubview(transcludeListView)
            
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
            // Handle select mode
            selectView.isHidden = !state.isBlockSelected
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
                    dom: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
                    transcludes: [
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/foo")!,
                            excerpt: Subtext(markup: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization."),
                            headers: WellKnownHeaders.emptySubtext
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/bar")!,
                            excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                            headers: WellKnownHeaders.emptySubtext
                        ),
                    ]
                )
            )
            return view
        }
    }
}
