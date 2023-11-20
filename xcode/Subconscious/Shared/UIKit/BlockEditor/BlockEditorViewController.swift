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
        
        private var state: BlockEditor.Model
        private var send: @MainActor (BlockEditor.Model.Action) -> Void
        
        init(
            state: BlockEditor.Model,
            send: @escaping @MainActor (BlockEditor.Model.Action) -> Void
        ) {
            Self.logger.log("init")
            self.state = state
            self.send = send
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
            initialize()
        }
        
        private func initialize() {
            self.collectionView.reloadData()
        }

        func update(_ next: BlockEditor.Model) {
            // If state has not changed, return early
            guard self.state != next else {
                return
            }
            let prev = self.state
            // Set state.
            // It's important to update the state before updating the UI,
            // since this is the data source for the UICollectionView.
            self.state = next
            Self.logger.log("State: \(String(describing: self.state))")
            updateBlocks(withPrevious: prev.blocks)
        }
        
        private func updateBlocks(
            withPrevious prev: [BlockEditor.BlockModel]
        ) {
            guard self.state.blocks != prev else {
                return
            }
            Self.logger.log("Update blocks")
            // Calculate insertions/addtions using the IDs of elements,
            // rather than their hash values. This allows us to track the
            // location and identity of blocks, even as they change value.
            let blocksDiff = state.blocks.differenceByID(
                from: prev
            )
            // Calculate changes to block data
            let blocksChanges = state.blocks.changes(from: prev)
            print("!!!", blocksDiff)
            print("!!!", blocksChanges)
            UIView.performWithoutAnimation {
                collectionView.performBatchUpdates {
                    for change in blocksDiff {
                        switch change {
                        case let .insert(offset, _, _):
                            self.collectionView.insertItems(
                                at: [
                                    IndexPath(
                                        row: offset,
                                        section: Section.blocks.rawValue
                                    )
                                ]
                            )
                        case let .remove(offset, _, _):
                            self.collectionView.deleteItems(
                                at: [
                                    IndexPath(
                                        row: offset,
                                        section: Section.blocks.rawValue
                                    )
                                ]
                            )
                        }
                    }
                    for change in blocksChanges {
                        switch change {
                        case .added(_, _):
                            continue
                        case let .updated(offset, _):
                            self.collectionView.reconfigureItems(
                                at: [
                                    IndexPath(
                                        row: offset,
                                        section: Section.blocks.rawValue
                                    )
                                ]
                            )
                        }
                    }
                }
            }
        }

        @objc private func onLongPress(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .ended:
                let point = gesture.location(in: self.collectionView)
                send(.longPress(point))
            default:
                break
            }
        }

        @objc private func onTap(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .ended:
                let point = gesture.location(in: self.collectionView)
                send(.tap(point))
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
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.autoresizingMask = [.flexibleHeight]
            
            collectionView.register(
                ErrorCell.self,
                forCellWithReuseIdentifier: ErrorCell.identifier
            )
            collectionView.register(
                TextBlockCell.self,
                forCellWithReuseIdentifier: TextBlockCell.identifier
            )
            collectionView.register(
                HeadingBlockCell.self,
                forCellWithReuseIdentifier: HeadingBlockCell.identifier
            )
            collectionView.register(
                QuoteBlockCell.self,
                forCellWithReuseIdentifier: QuoteBlockCell.identifier
            )
            collectionView.register(
                ListBlockCell.self,
                forCellWithReuseIdentifier: ListBlockCell.identifier
            )
            collectionView.register(
                RelatedCell.self,
                forCellWithReuseIdentifier: RelatedCell.identifier
            )
            
            return collectionView
        }
    }
}

// MARK: TextBlockDelegate
extension BlockEditor.ViewController: TextBlockDelegate {
    func boldButtonPressed(id: UUID, text: String, selection: NSRange) {
        send(.insertBold(id: id, selection: selection))
    }
    
    func italicButtonPressed(id: UUID, text: String, selection: NSRange) {
        send(.insertItalic(id: id, selection: selection))
    }
    
    func codeButtonPressed(id: UUID, text: String, selection: NSRange) {
        send(.insertCode(id: id, selection: selection))
    }
    
    func requestSplit(id: UUID, selection: NSRange) {
        send(.splitBlock(id: id, selection: selection))
    }
    
    func requestMerge(id: UUID) {
        send(.mergeBlockUp(id: id))
    }
    
    func didChange(id: UUID, text: String, selection: NSRange) {
        self.send(
            .textDidChange(
                id: id,
                text: text,
                selection: selection
            )
        )
    }

    func didChangeSelection(id: UUID, selection: NSRange) {
        self.send(
            .didChangeSelection(
                id: id,
                selection: selection
            )
        )
    }
    
    func didBeginEditing(id: UUID) {
        self.send(.focus(id: id))
    }
    
    func didEndEditing(id: UUID) {
        self.send(.blur(id: id))
    }
    
    func upButtonPressed(id: UUID) {
        send(.moveBlockUp(id: id))
    }
    
    func downButtonPressed(id: UUID) {
        send(.moveBlockDown(id: id))
    }
    
    func dismissKeyboardButtonPressed(id: UUID) {
        send(.renderBlur(id: id))
    }
}

extension BlockEditor.ViewController: UICollectionViewDataSource {
    typealias Section = BlockEditor.Section
    typealias TextBlockModel = BlockEditor.TextBlockModel
    typealias ErrorCell = BlockEditor.ErrorCell
    typealias TextBlockCell = BlockEditor.TextBlockCell
    typealias HeadingBlockCell = BlockEditor.HeadingBlockCell
    typealias QuoteBlockCell = BlockEditor.QuoteBlockCell
    typealias ListBlockCell = BlockEditor.ListBlockCell
    typealias RelatedCell = BlockEditor.RelatedCell
    
    /// Return 2 sections
    /// - 1 blocks
    /// - 2 "footer" containing related notes
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }
    
    /// Provides a count for data in a particular section
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        switch Section(rawValue: section) {
        case .blocks:
            return state.blocks.count
        case .appendix:
            return 1
        default:
            return 0
        }
    }
    
    /// Provides a UICollectionViewCell for an index path.
    /// This method is responsible for looking up data from a data source
    /// (state in our case) using the index path.
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section) {
        case .blocks:
            return blockCell(collectionView, forItemAt: indexPath)
        case .appendix:
            return appendixCell(collectionView, forItemAt: indexPath)
        default:
            return errorCell(collectionView, forItemAt: indexPath)
        }
    }
    
    /// Error cells are dequeued when we don't know what else to display.
    ///
    /// Error cells should never be displayed in practice, but we must
    /// have something to dequeue since `collectionView(_:cellForItemAt:)`
    /// requires a cell to be returned for every case.
    private func errorCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ErrorCell.identifier,
            for: indexPath
        ) as! ErrorCell
        return cell
    }
    
    private func blockCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let block = state.blocks[indexPath.row]
        switch block {
        case let .heading(state):
            return headingCell(
                collectionView,
                forItemAt: indexPath,
                state: state
            )
        case let .text(state):
            return textCell(
                collectionView,
                forItemAt: indexPath,
                state: state
            )
        case let .quote(state):
            return quoteCell(
                collectionView,
                forItemAt: indexPath,
                state: state
            )
        case let .list(state):
            return listCell(
                collectionView,
                forItemAt: indexPath,
                state: state
            )
        }
    }
    
    private func textCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath,
        state: TextBlockModel
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TextBlockCell.identifier,
            for: indexPath
        ) as! TextBlockCell
        cell.delegate = self
        cell.update(parentController: self, state: state)
        return cell
    }
    
    private func headingCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath,
        state: TextBlockModel
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HeadingBlockCell.identifier,
            for: indexPath
        ) as! HeadingBlockCell
        cell.delegate = self
        cell.update(state)
        return cell
    }
    
    private func quoteCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath,
        state: TextBlockModel
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: QuoteBlockCell.identifier,
            for: indexPath
        ) as! QuoteBlockCell
        cell.delegate = self
        cell.update(parentController: self, state: state)
        return cell
    }
    
    private func listCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath,
        state: TextBlockModel
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ListBlockCell.identifier,
            for: indexPath
        ) as! ListBlockCell
        cell.delegate = self
        cell.update(parentController: self, state: state)
        return cell
    }
    
    private func appendixCell(
        _ collectionView: UICollectionView,
        forItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RelatedCell.identifier,
            for: indexPath
        ) as! RelatedCell
        let state = state.appendix
        cell.update(parentController: self, state: state)
        return cell
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
