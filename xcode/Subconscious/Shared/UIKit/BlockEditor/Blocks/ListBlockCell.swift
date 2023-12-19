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
        UITextViewDelegate
    {
        static let identifier = "ListBlockCell"
        
        typealias TranscludeListView = BlockEditor.TranscludeListView
        
        var id: UUID = UUID()
        
        var send: (TextBlockAction) -> Void = { _ in }

        private lazy var selectView = BlockEditor.BlockSelectView()
        private lazy var stackView = UIStackView()
        private var listContainerMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppTheme.unit4,
            bottom: 0,
            trailing: 0
        )
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
            listContainer.addSubview(textView)
            
            listContainer.addSubview(bulletView)
            
            stackView.addArrangedSubview(transcludeListView)
            
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
        
        private func createBulletView() -> UIView {
            let bulletSize: CGFloat = 6
            let frameWidth: CGFloat = AppTheme.unit2
            let lineHeight: CGFloat = AppTheme.lineHeight
            
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
            // Handle select mode
            selectView.isHidden = !state.isBlockSelected
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
