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
    /// Manages the "DOM" of the editor.
    class ViewController:
        UIViewController,
        UICollectionViewDelegateFlowLayout,
        UICollectionViewDataSource
    {
        typealias Store = ControllerStore.Store<BlockEditor.ViewController>
        
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
            config.footerMode = .supplementary
            config.showsSeparators = false
            let layout = UICollectionViewCompositionalLayout.list(
                using: config
            )

            return UICollectionView(
                frame: frame,
                collectionViewLayout: layout
            )
        }
        
        private lazy var collectionView = Self.createCollectionView(
            frame: .zero
        )
        let store: ControllerStore.Store<BlockEditor.ViewController>
        
        init(store: Store) {
            Self.logger.log("init")
            self.store = store
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            collectionView.register(
                Footer.self,
                forSupplementaryViewOfKind:
                    UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: Footer.identifier
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
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.autoresizingMask = [.flexibleHeight]
            collectionView.delegate = self
            collectionView.dataSource = self
            view.addSubview(collectionView)
            
            NSLayoutConstraint.activate([
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            self.store.connect(self)
        }
        
        /// Provides supplementary views for our UICollection such as headers
        /// and footers.
        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {
            // We currentl only implement footers, so always dequeue a footer
            // for now.
            collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: Footer.identifier,
                for: indexPath
            )
        }
        
        /// Provides a count for data in a particular section
        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {
            store.state.blocks.count
        }
        
        /// Provides a UICollectionViewCell for an index path.
        /// This method is responsible for looking up data from a data source
        /// (state in our case) using the index path.
        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
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
            cell.render(state)
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
            cell.render(state)
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
            cell.render(state)
            return cell
        }
    }
}

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
    //  MARK: Actions
    enum Action: Hashable {
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

//  MARK: Controller
extension BlockEditor.ViewController: ControllerStoreControllerProtocol {
    typealias Model = BlockEditor.Model
    typealias Action = BlockEditor.Action
    
    func reconfigure(
        state: BlockEditor.Model,
        send: @escaping (BlockEditor.Action) -> Void
    ) {
        self.collectionView.reloadData()
    }
    
    func update(
        state: Model,
        action: Action
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
        
        let indexPathB = IndexPath(row: indexB)
        
        let render = {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates(
                    {
                        self.collectionView.reconfigureItems(
                            at: [IndexPath(row: indexA)]
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
        
        let indexPathUp = IndexPath(row: indexUp)
        
        let render = {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates(
                    {
                        self.collectionView.reconfigureItems(
                            at: [indexPathUp]
                        )
                        self.collectionView.deleteItems(
                            at: [IndexPath(row: indexDown)]
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
            block.setFocus(block.id == id)
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
        let indexPath = IndexPath(row: index)
        var model = state
        model.blocks = state.blocks.map({ block in
            block.setFocus(block.id == id)
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
                return block.setFocus(false)
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
        let indexPath = IndexPath(row: index)
        var model = state
        model.blocks = state.blocks.map({ block in
            if block.id == id {
                return block.setFocus(false)
            }
            return block
        })
        
        let render = {
            self.collectionView.reconfigureItems(at: [indexPath])
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
        
        collectionView.moveItem(
            at: IndexPath(row: i),
            to: IndexPath(row: h)
        )
        
        return Update(state: model)
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
            at: IndexPath(row: i),
            to: IndexPath(row: j)
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
            let indexPath = IndexPath(row: i)
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
