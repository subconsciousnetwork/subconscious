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
        UICollectionViewDelegateFlowLayout,
        UICollectionViewDataSource
    {
        static var logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditorViewController"
        )
        
        /// Create a configured collection view suitable for our block editor
        private static func createCollectionView(
            frame: CGRect
        ) -> UICollectionView {
            var config = UICollectionLayoutListConfiguration(
                appearance: .plain
            )
            config.showsSeparators = false
            let layout = UICollectionViewCompositionalLayout.list(
                using: config
            )
            
            let collectionView = UICollectionView(
                frame: frame,
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

        private lazy var collectionView = Self.createCollectionView(
            frame: .zero
        )
        
        let store: BlockEditorStore
        
        init(store: BlockEditorStore) {
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
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.autoresizingMask = [.flexibleHeight]
            collectionView.delegate = self
            collectionView.dataSource = self
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
            
            self.store.controller = self
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
                return store.state.blocks.count
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
            let block = store.state.blocks[indexPath.row]
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
            cell.render(state)
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
            let state = store.state.appendix
            cell.update(parentController: self, state: state)
            return cell
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

extension BlockEditor {
    // MARK: Actions
    enum Action {
        case textDidChange(id: UUID?, text: String, selection: NSRange)
        case didChangeSelection(id: UUID, selection: NSRange)
        case splitBlock(id: UUID, selection: NSRange)
        case mergeBlockUp(id: UUID)
        /// Record a focus from the user
        case focus(id: UUID)
        /// Force a focus
        case renderFocus(id: UUID)
        /// Record a blur from the user
        case blur(id: UUID)
        /// Force a blur
        case renderBlur(id: UUID)
        /// Issues a long-press event at a point.
        /// If the point matches a block, this will enter edit mode.
        case longPress(CGPoint)
        /// Issues a tap event at a point.
        /// If the point matches a block, and the editor is in selection mode,
        /// this will toggle block selection.
        case tap(CGPoint)
        /// Enter edit mode, optionally selecting a block
        case enterBlockSelectMode(selecting: UUID?)
        /// Exit edit mode. Also de-selects all blocks
        case exitBlockSelectMode
        /// Select a block
        case selectBlock(id: UUID, isSelected: Bool = true)
        case toggleSelectBlock(id: UUID)
        /// Move the block up one position in the stack.
        /// If block is first block, this does nothing.
        case moveBlockUp(id: UUID)
        /// Move the block up down position in the stack.
        /// If block is last block, this does nothing.
        case moveBlockDown(id: UUID)
        case insertBold(id: UUID, selection: NSRange)
        case insertItalic(id: UUID, selection: NSRange)
        case insertCode(id: UUID, selection: NSRange)
    }
}

// MARK: Controller
extension BlockEditor.ViewController: ControllerStoreUpdateableProtocol {
    typealias Model = BlockEditor.Model
    typealias Action = BlockEditor.Action
    typealias Environment = AppEnvironment
    typealias Update = ControllerStore.Update<Model, Action>
    
    func update(
        state: Model,
        action: Action,
        environment: AppEnvironment
    ) -> Update {
        switch action {
        case let .textDidChange(id, text, selection):
            return textDidChange(
                state: state,
                id: id,
                text: text,
                selection: selection
            )
        case let .didChangeSelection(id, selection):
            return didChangeSelection(
                state: state,
                id: id,
                selection: selection
            )
        case let .splitBlock(id, selection):
            return splitBlock(
                state: state,
                id: id,
                selection: selection
            )
        case let .mergeBlockUp(id):
            return mergeBlockUp(
                state: state,
                id: id
            )
        case let .focus(id):
            return focus(
                state: state,
                id: id
            )
        case let .renderFocus(id):
            return renderFocus(
                state: state,
                id: id
            )
        case let .blur(id):
            return blur(
                state: state,
                id: id
            )
        case let .renderBlur(id):
            return renderBlur(
                state: state,
                id: id
            )
        case let .longPress(point):
            return longPress(
                state: state,
                point: point
            )
        case let .tap(point):
            return tap(
                state: state,
                point: point
            )
        case let .enterBlockSelectMode(selecting):
            return enterBlockSelectMode(
                state: state,
                selecting: selecting
            )
        case .exitBlockSelectMode:
            return exitBlockSelectMode(
                state: state
            )
        case let .selectBlock(id, isSelected):
            return selectBlock(
                state: state,
                id: id,
                isSelected: isSelected
            )
        case let .toggleSelectBlock(id: id):
            return toggleSelectBlock(
                state: state,
                id: id
            )
        case let .moveBlockUp(id):
            return moveBlockUp(
                state: state,
                id: id
            )
        case let .moveBlockDown(id):
            return moveBlockDown(
                state: state,
                id: id
            )
        case let .insertBold(id, selection):
            return insertBold(
                state: state,
                id: id,
                selection: selection
            )
        case let .insertItalic(id, selection):
            return insertItalic(
                state: state,
                id: id,
                selection: selection
            )
        case let .insertCode(id, selection):
            return insertCode(
                state: state,
                id: id,
                selection: selection
            )
        }
    }
    
    func textDidChange(
        state: Model,
        id: UUID?,
        text: String,
        selection: NSRange
    ) -> Update {
        guard let id = id else {
            Self.logger.log("No block id. Doing nothing.")
            return Update(state: state)
        }
        guard let i = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        var model = state
        let block = state.blocks[i].setText(text: text, selection: selection)
        
        guard let block = block else {
            Self.logger.log("block#\(id) could not update block text. Doing nothing.")
            return Update(state: state)
        }
        
        model.blocks[i] = block
        
        return Update(state: model)
    }
    
    func didChangeSelection(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update {
        guard let i = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        var model = state
        guard let block = state.blocks[i].setSelection(
            selection: selection
        ) else {
            Self.logger.log("block#\(id) could not update block selection. Doing nothing.")
            return Update(state: state)
        }
        model.blocks[i] = block
        return Update(state: model)
    }
    
    func splitBlock(
        state: Model,
        id: UUID,
        selection nsRange: NSRange
    ) -> Update {
        guard let indexA = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        Self.logger.log("block#\(id) splitting at \(nsRange.location)")
        
        let blockA = state.blocks[indexA]
        
        guard let blockTextA = blockA.text else {
            Self.logger.log("block#\(id) cannot split block without text. Doing nothing.")
            return Update(state: state)
        }
        
        guard let (textA, textB) = blockTextA.splitAtRange(nsRange) else {
            Self.logger.log(
                "block#\(id) could not split text at range. Doing nothing."
            )
            return Update(state: state)
        }
        
        guard let blockA = blockA.setText(
            text: textA,
            selection: NSRange(location: nsRange.location, length: 0)
        ) else {
            Self.logger.log(
                "block#\(id) could set text. Doing nothing."
            )
            return Update(state: state)
        }

        var blockB = BlockEditor.TextBlockModel()
        blockB.text = textB
        
        let indexB = state.blocks.index(after: indexA)
        var model = state
        model.blocks[indexA] = blockA
        model.blocks.insert(
            .text(blockB),
            at: indexB
        )
        
        let indexPathB = IndexPath(
            row: indexB,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        let render = {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates(
                    {
                        self.collectionView.reconfigureItems(
                            at: [
                                IndexPath(
                                    row: indexA,
                                    section: BlockEditor.Section.blocks.rawValue
                                )
                            ]
                        )
                        self.collectionView.insertItems(
                            at: [indexPathB]
                        )
                    },
                    completion: { isComplete in
                        self.store.send(.renderFocus(id: blockB.id))
                    }
                )
            }
        }
        
        return Update(state: model, render: render)
    }
    
    func mergeBlockUp(
        state: Model,
        id: UUID
    ) -> Update {
        guard let indexDown = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        guard indexDown > 0 else {
            Self.logger.log("block#\(id) is first block. Skipping merge up.")
            return Update(state: state)
        }
        Self.logger.log("block#\(id) merging up")
        
        let indexUp = state.blocks.index(before: indexDown)
        let blockUp = state.blocks[indexUp]
        
        guard let blockUpText = blockUp.text else {
            Self.logger.log("block#\(id) cannot merge up into block without text. Doing nothing.")
            return Update(state: state)
        }
        
        let blockDown = state.blocks[indexDown]
        guard let blockDownText = blockDown.text else {
            Self.logger.log("block#\(id) cannot merge non-text block. Doing nothing.")
            return Update(state: state)
        }

        let selectionNSRange = NSRange(
            blockUpText.endIndex..<blockUpText.endIndex,
            in: blockUpText
        )
        
        guard let blockUp = blockUp.setText(
            text: blockUpText + blockDownText,
            selection: selectionNSRange
        ) else {
            Self.logger.log("block#\(id) could not merge text. Doing nothing.")
            return Update(state: state)
        }
        
        var model = state
        model.blocks[indexUp] = blockUp
        model.blocks.remove(at: indexDown)
        
        let indexPathUp = IndexPath(
            row: indexUp,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        let render = {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates(
                    {
                        self.collectionView.reconfigureItems(
                            at: [indexPathUp]
                        )
                        self.collectionView.deleteItems(
                            at: [
                                IndexPath(
                                    row: indexDown,
                                    section: BlockEditor.Section.blocks.rawValue
                                )
                            ]
                        )
                    },
                    completion: { isComplete in
                        self.store.send(.renderFocus(id: blockUp.id))
                    }
                )
            }
        }

        return Update(state: model, render: render)
    }
    
    func focus(
        state: Model,
        id: UUID
    ) -> Update {
        var model = state
        model.blocks = state.blocks.map({ block in
            block.setEditing(block.id == id) ?? block
        })
        return Update(state: model)
    }
    
    func renderFocus(
        state: Model,
        id: UUID
    ) -> Update {
        guard let index = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) no block found with ID. Doing nothing.")
            return Update(state: state)
        }
        
        let indexPath = IndexPath(
            row: index,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        var model = state
        model.blocks = state.blocks.map({ block in
            block.setEditing(block.id == id) ?? block
        })

        let render = {
            self.collectionView.reconfigureItems(at: [indexPath])
        }
        
        return Update(state: model, render: render)
    }
    
    func blur(
        state: Model,
        id: UUID
    ) -> Update {
        var model = state
        model.blocks = state.blocks.map({ block in
            if block.id == id {
                return block.setEditing(false) ?? block
            }
            return block
        })
        return Update(state: model)
    }
    
    func renderBlur(
        state: Model,
        id: UUID
    ) -> Update {
        guard let index = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) no block found with ID. Doing nothing.")
            return Update(state: state)
        }
        
        let indexPath = IndexPath(
            row: index,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        var model = state
        model.blocks = state.blocks.map({ block in
            if block.id == id {
                return block.setEditing(false) ?? block
            }
            return block
        })
        
        let render = {
            self.collectionView.reconfigureItems(at: [indexPath])
        }
        
        return Update(state: model, render: render)
    }
    
    func longPress(
        state: Model,
        point: CGPoint
    ) -> Update {
        guard !state.isBlockSelectMode else {
            return Update(state: state)
        }
        Self.logger.debug("Long press triggering select mode")
        guard let indexPath = collectionView.indexPathForItem(at: point) else {
            let x = point.x
            let y = point.y
            Self.logger.debug("No block at point (\(x), \(y)). No-op.")
            return Update(state: state)
        }
        let index = indexPath.row
        guard let block = state.blocks.get(index) else {
            Self.logger.log("No model found at index \(index). No-op.")
            return Update(state: state)
        }
        let selectModeEffect = {
            Action.enterBlockSelectMode(selecting: block.id)
        }
        return Update(state: state, effects: [selectModeEffect])
    }
    
    func tap(
        state: Model,
        point: CGPoint
    ) -> Update {
        guard state.isBlockSelectMode else {
            return Update(state: state)
        }
        Self.logger.debug("Tap triggering block selection")
        guard let indexPath = collectionView.indexPathForItem(at: point) else {
            let x = point.x
            let y = point.y
            Self.logger.debug("No block at point (\(x), \(y)). No-op.")
            return Update(state: state)
        }
        let index = indexPath.row
        guard let block = state.blocks.get(index) else {
            Self.logger.log("No model found at index \(index). No-op.")
            return Update(state: state)
        }
        let selectModeEffect = {
            Action.toggleSelectBlock(id: block.id)
        }
        return Update(state: state, effects: [selectModeEffect])
    }

    func enterBlockSelectMode(
        state: Model,
        selecting id: UUID?
    ) -> Update {
        var model = state
        
        model.isBlockSelectMode = true
        model.blocks = state.blocks.map({ block in
            let updated = block.update { block in
                var block = block
                block.isBlockSelectMode = true
                block.isBlockSelected = block.id == id
                return block
            }
            return updated ?? block
        })
        
        let render = {
            self.collectionView.reloadSections(
                IndexSet(
                    integer: BlockEditor.Section.blocks.rawValue
                )
            )
        }
        
        return Update(state: model, render: render)
    }
    
    func exitBlockSelectMode(
        state: Model
    ) -> Update {
        var model = state
        
        model.isBlockSelectMode = false
        model.blocks = state.blocks.map({ block in
            let updated = block.update { block in
                var block = block
                block.isBlockSelectMode = false
                block.isBlockSelected = false
                return block
            }
            return updated ?? block
        })
        
        let render = {
            self.collectionView.reloadSections(
                IndexSet(
                    integer: BlockEditor.Section.blocks.rawValue
                )
            )
        }
        
        return Update(state: model, render: render)
    }

    private func updateBlock(
        state: Model,
        id: UUID,
        transform: (BlockEditor.BlockModel) -> BlockEditor.BlockModel
    ) -> Model? {
        guard let i = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return nil
        }
        var model = state
        let block = model.blocks[i]
        model.blocks[i] = transform(block)
        return model
    }

    func selectBlock(
        state: Model,
        id: UUID,
        isSelected: Bool
    ) -> Update {
        guard state.isBlockSelectMode else {
            Self.logger.log("block#\(id) selected, but not in select mode. Doing nothing.")
            return Update(state: state)
        }
        
        guard let i = state.block(id: id) else {
            return Update(state: state)
        }
        
        var model = state
        let block = model.blocks[i]
        let updatedBlock = block.setBlockSelected(isSelected) ?? block

        guard block != updatedBlock else {
            Self.logger.debug("Block selection state did not change.")
            return Update(state: state)
        }
        model.blocks[i] = updatedBlock
        
        let render = {
            self.collectionView.reconfigureItems(
                at: [
                    IndexPath(
                        row: i,
                        section: BlockEditor.Section.blocks.rawValue
                    )
                ]
            )
        }
        
        return Update(state: model, render: render)
    }

    func toggleSelectBlock(
        state: Model,
        id: UUID
    ) -> Update {
        guard state.isBlockSelectMode else {
            Self.logger.log("block#\(id) selected, but not in select mode. Doing nothing.")
            return Update(state: state)
        }
        
        guard let i = state.block(id: id) else {
            return Update(state: state)
        }
        
        var model = state
        let block = model.blocks[i]
        let isSelected = block.isBlockSelected
        let updatedBlock = block.setBlockSelected(!isSelected) ?? block

        guard block != updatedBlock else {
            Self.logger.debug("Block selection state did not change.")
            return Update(state: state)
        }
        model.blocks[i] = updatedBlock
        
        let render = {
            self.collectionView.reconfigureItems(
                at: [
                    IndexPath(
                        row: i,
                        section: BlockEditor.Section.blocks.rawValue
                    )
                ]
            )
        }
        
        return Update(state: model, render: render)
    }

    func moveBlockUp(
        state: Model,
        id: UUID
    ) -> Update {
        guard let i = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        var blocksArray = state.blocks
        
        guard i > blocksArray.startIndex else {
            Self.logger.log("block#\(id) can't move up first block. Doing nothing.")
            return Update(state: state)
        }
        
        let h = blocksArray.index(before: i)
        blocksArray.swapAt(h, i)
        var model = state
        model.blocks = blocksArray
        
        let render = {
            self.collectionView.moveItem(
                at: IndexPath(
                    row: i,
                    section: BlockEditor.Section.blocks.rawValue
                ),
                to: IndexPath(
                    row: h,
                    section: BlockEditor.Section.blocks.rawValue
                )
            )
        }
        
        return Update(state: model, render: render)
    }
    
    func moveBlockDown(
        state: Model,
        id: UUID
    ) -> Update {
        guard let i = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        var blocksArray = state.blocks
        
        let lastItemIndex = blocksArray.index(before: blocksArray.endIndex)
        guard i < lastItemIndex else {
            Self.logger.log("block#\(id) can't move down last block. Doing nothing.")
            return Update(state: state)
        }
        
        let j = blocksArray.index(after: i)
        blocksArray.swapAt(i, j)
        
        var model = state
        model.blocks = blocksArray
        
        collectionView.moveItem(
            at: IndexPath(
                row: i,
                section: BlockEditor.Section.blocks.rawValue
            ),
            to: IndexPath(
                row: j,
                section: BlockEditor.Section.blocks.rawValue
            )
        )
        return Update(state: model)
    }
        
    /// Insert markup at range within a block
    func insertMarkup(
        state: Model,
        id: UUID,
        selection: NSRange,
        replace: (
            String,
            Range<String.Index>
        ) -> BlockEditor.SubtextEditorMarkup.Replacement?
    ) -> Update {
        guard let i = state.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        let block = state.blocks[i]

        guard let text = block.text else {
            Self.logger.log("block#\(id) can't insert markup. Block has no text. Doing nothing.")
            return Update(state: state)
        }

        guard let selectedRange = Range(selection, in: text) else {
            Self.logger.log("block#\(id) could not find text in range. Doing nothing.")
            return Update(state: state)
        }

        guard let replacement = replace(
            text,
            selectedRange
        ) else {
            Self.logger.log("block#\(id) could make replacement for range. Doing nothing.")
            return Update(state: state)
        }
        
        // Find new selection position
        let cursorNSRange = NSRange(
            replacement.tagContent,
            in: replacement.string
        )
        
        guard let block = block.setText(
            text: replacement.string,
            selection: cursorNSRange
        ) else {
            Self.logger.log("block#\(id) could not set text. Doing nothing.")
            return Update(state: state)
        }
        
        var model = state
        model.blocks[i] = block
        
        let render = {
            let indexPath = IndexPath(
                row: i,
                section: BlockEditor.Section.blocks.rawValue
            )
            self.collectionView.reconfigureItems(at: [indexPath])
        }

        return Update(state: model, render: render)
    }

    func insertBold(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update {
        insertMarkup(
            state: state,
            id: id,
            selection: selection,
            replace: BlockEditor.SubtextEditorMarkup.wrapBold
        )
    }
    
    func insertItalic(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update {
        insertMarkup(
            state: state,
            id: id,
            selection: selection,
            replace: BlockEditor.SubtextEditorMarkup.wrapItalic
        )
    }
    
    func insertCode(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update {
        insertMarkup(
            state: state,
            id: id,
            selection: selection,
            replace: BlockEditor.SubtextEditorMarkup.wrapCode
        )
    }
}

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
