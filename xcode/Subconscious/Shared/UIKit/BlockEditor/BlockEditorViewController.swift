//
//  BlockEditorViewController.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import UIKit
import Combine
import os

extension BlockEditor {
    /// Represents the sections in the collection view.
    enum Section: Int, CaseIterable {
        case blocks = 0
        case appendix = 1
    }
}

extension BlockEditor {
    /// Manages the "DOM" of the editor.
    class ViewController:
        UIViewController,
        UICollectionViewDelegateFlowLayout
    {
        static var logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditorViewController"
        )
        
        /// Gesture used to toggle into block selection mode
        private lazy var longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(onLongPress)
        )

        /// Gesture used to select blocks in selection mode
        private lazy var tapGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(onTap)
        )

        private lazy var collectionView = createCollectionView()
        
        private lazy var dataSource = createDataSource(
            collectionView: collectionView
        )
        
        private var store: BlockEditorStore
        
        init(
            store: BlockEditorStore
        ) {
            Self.logger.log("init")
            self.store = store
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            longPressGesture.delegate = self
            view.addGestureRecognizer(longPressGesture)

            tapGesture.delegate = self
            view.addGestureRecognizer(tapGesture)
            
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.autoresizingMask = [.flexibleHeight]
            collectionView.delegate = self
            view.addSubview(collectionView)
            
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                collectionView.leadingAnchor.constraint(
                    equalTo: guide.leadingAnchor
                ),
                collectionView.trailingAnchor.constraint(
                    equalTo: guide.trailingAnchor
                ),
                collectionView.topAnchor.constraint(
                    equalTo: guide.topAnchor
                ),
                collectionView.bottomAnchor.constraint(
                    equalTo: guide.bottomAnchor
                ),
            ])
        }
        
        func update(state: BlockEditor.Model) {
            print("!!! hit")
            var snapshot = NSDiffableDataSourceSnapshot
                <BlockEditor.Section, BlockEditor.CellModel>()
            snapshot.appendSections([.blocks, .appendix])
            snapshot.appendItems(
                state.blocks.map({ block in .init(content: .blocks(block))}),
                toSection: .blocks
            )
            dataSource.apply(snapshot, animatingDifferences: true)
        }

        @objc private func onLongPress(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .ended:
                let point = gesture.location(in: self.collectionView)
                store.send(.longPress(point))
            default:
                break
            }
        }

        @objc private func onTap(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .ended:
                let point = gesture.location(in: self.collectionView)
                store.send(.tap(point))
            default:
                break
            }
        }

        /// Create a configured collection view suitable for our block editor
        private func createCollectionView() -> UICollectionView {
            var config = UICollectionLayoutListConfiguration(
                appearance: .plain
            )
            config.showsSeparators = false
            let layout = UICollectionViewCompositionalLayout.list(
                using: config
            )
            
            let collectionView = UICollectionView(
                frame: .zero,
                collectionViewLayout: layout
            )
            collectionView.contentInset = UIEdgeInsets(
                top: AppTheme.unit2,
                left: 0,
                bottom: AppTheme.unit2,
                right: 0
            )
            return collectionView
        }
        
        private func createDataSource(
            collectionView: UICollectionView
        ) -> UICollectionViewDiffableDataSource<Section, CellModel> {
            var textCellRegistration = UICollectionView
                .CellRegistration<TextBlockCell, TextBlockModel> {
                    cell, indexPath, item in
                    cell.update(
                        parentController: self,
                        state: item
                    )
                }

            var headingCellRegistration = UICollectionView
                .CellRegistration<HeadingBlockCell, TextBlockModel> {
                    cell, indexPath, item in
                    cell.render(item)
                }
            
            var listCellRegistration = UICollectionView
                .CellRegistration<ListBlockCell, TextBlockModel> {
                    cell, indexPath, item in
                    cell.update(parentController: self, state: item)
                }
            
            var quoteCellRegistration = UICollectionView
                .CellRegistration<QuoteBlockCell, TextBlockModel> {
                    cell, indexPath, item in
                    cell.update(parentController: self, state: item)
                }
            
            var appendixCellRegistration = UICollectionView
                .CellRegistration<RelatedCell, RelatedModel> {
                    cell, indexPath, item in
                    cell.update(parentController: self, state: item)
                }

            let dataSource = UICollectionViewDiffableDataSource<Section, CellModel>(
                collectionView: collectionView,
                cellProvider: { collectionView, indexPath, item in
                    switch item.content {
                    case .blocks(let block):
                        switch block {
                        case .text(let text):
                            return collectionView.dequeueConfiguredReusableCell(
                                using: textCellRegistration,
                                for: indexPath,
                                item: text
                            )
                        case .heading(let text):
                            return collectionView.dequeueConfiguredReusableCell(
                                using: headingCellRegistration,
                                for: indexPath,
                                item: text
                            )
                        case .list(let text):
                            return collectionView.dequeueConfiguredReusableCell(
                                using: listCellRegistration,
                                for: indexPath,
                                item: text
                            )
                        case .quote(let text):
                            return collectionView.dequeueConfiguredReusableCell(
                                using: quoteCellRegistration,
                                for: indexPath,
                                item: text
                            )
                        }
                    case .appendix(let related):
                        return collectionView.dequeueConfiguredReusableCell(
                            using: appendixCellRegistration,
                            for: indexPath,
                            item: related
                        )
                    }
                }
            )
            collectionView.dataSource = dataSource
            return dataSource
        }
    }
}

// MARK: TextBlockDelegate
extension BlockEditor.ViewController: TextBlockDelegate {
    func boldButtonPressed(id: UUID, text: String, selection: NSRange) {
        store.send(.insertBold(id: id, selection: selection))
    }
    
    func italicButtonPressed(id: UUID, text: String, selection: NSRange) {
        store.send(.insertItalic(id: id, selection: selection))
    }
    
    func codeButtonPressed(id: UUID, text: String, selection: NSRange) {
        store.send(.insertCode(id: id, selection: selection))
    }
    
    func requestSplit(id: UUID, selection: NSRange) {
        store.send(.splitBlock(id: id, selection: selection))
    }
    
    func requestMerge(id: UUID) {
        store.send(.mergeBlockUp(id: id))
    }
    
    func didChange(id: UUID, text: String, selection: NSRange) {
        store.send(
            .textDidChange(
                id: id,
                text: text,
                selection: selection
            )
        )
    }

    func didChangeSelection(id: UUID, selection: NSRange) {
        store.send(
            .didChangeSelection(
                id: id,
                selection: selection
            )
        )
    }
    
    func didBeginEditing(id: UUID) {
        store.send(.focus(id: id))
    }
    
    func didEndEditing(id: UUID) {
        store.send(.blur(id: id))
    }
    
    func upButtonPressed(id: UUID) {
        store.send(.moveBlockUp(id: id))
    }
    
    func downButtonPressed(id: UUID) {
        store.send(.moveBlockDown(id: id))
    }
    
    func dismissKeyboardButtonPressed(id: UUID) {
        store.send(.renderBlur(id: id))
    }
}

extension BlockEditor.ViewController: HeadingBlockCellDelegate {}

// MARK: UIGestureRecognizerDelegate
extension BlockEditor.ViewController: UIGestureRecognizerDelegate {
    /// Recognize long-press gesture simultaneously with other gestures.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
