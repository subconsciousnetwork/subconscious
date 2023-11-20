//
//  BlockStackEditorModle.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/28/23.
//
import Foundation
import ObservableStore
import os
import Combine

extension BlockEditor {
    // MARK: Model
    struct Model: Hashable {
        static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditor.Model"
        )

        /// Create a BlockEditor "draft" document.
        /// A draft is a document with a heading block and nothing else.
        static func draft() -> Self {
            Self(
                blocks: [
                    BlockEditor.BlockModel.heading(
                        BlockEditor.TextBlockModel()
                    )
                ]
            )
        }

        var isBlockSelectMode = false
        var blocks: [BlockEditor.BlockModel] = []
        var appendix = BlockEditor.RelatedModel()

        func blockIndex(id: UUID) -> Array.Index? {
            guard let i = blocks.firstIndex(whereID: id) else {
                Self.logger.log("block#\(id) not found.")
                return nil
            }
            return i
        }

        func block(id: UUID) -> BlockModel? {
            guard let i = blockIndex(id: id) else {
                return nil
            }
            return blocks[i]
        }
    }
}

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

extension BlockEditor.Model: ModelProtocol {
    typealias Model = BlockEditor.Model
    typealias Action = BlockEditor.Action
    typealias Environment = AppEnvironment

    static func update(
        state: Model,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
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

    private static func textDidChange(
        state: Model,
        id: UUID?,
        text: String,
        selection: NSRange
    ) -> Update<Self> {
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

    private static func didChangeSelection(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update<Self> {
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

    private static func splitBlock(
        state: Model,
        id: UUID,
        selection nsRange: NSRange
    ) -> Update<Self> {
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
        let fx: Fx<BlockEditor.Action> = Just(.renderFocus(id: blockB.id))
            .eraseToAnyPublisher()
        
        //        let indexPathB = IndexPath(
//            row: indexB,
//            section: BlockEditor.Section.blocks.rawValue
//        )

//        let render = {
//            UIView.performWithoutAnimation {
//                self.collectionView.performBatchUpdates(
//                    {
//                        self.collectionView.reconfigureItems(
//                            at: [
//                                IndexPath(
//                                    row: indexA,
//                                    section: BlockEditor.Section.blocks.rawValue
//                                )
//                            ]
//                        )
//                        self.collectionView.insertItems(
//                            at: [indexPathB]
//                        )
//                    },
//                    completion: { isComplete in
//                        self.store.send(.renderFocus(id: blockB.id))
//                    }
//                )
//            }
//        }

        return Update(state: model, fx: fx)
    }

    private static func mergeBlockUp(
        state: Model,
        id: UUID
    ) -> Update<Self> {
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
        
        let fx: Fx<BlockEditor.Action> = Just(.renderFocus(id: blockUp.id))
            .eraseToAnyPublisher()

//        let indexPathUp = IndexPath(
//            row: indexUp,
//            section: BlockEditor.Section.blocks.rawValue
//        )

//        let render = {
//            UIView.performWithoutAnimation {
//                self.collectionView.performBatchUpdates(
//                    {
//                        self.collectionView.reconfigureItems(
//                            at: [indexPathUp]
//                        )
//                        self.collectionView.deleteItems(
//                            at: [
//                                IndexPath(
//                                    row: indexDown,
//                                    section: BlockEditor.Section.blocks.rawValue
//                                )
//                            ]
//                        )
//                    },
//                    completion: { isComplete in
//                        self.store.send(.renderFocus(id: blockUp.id))
//                    }
//                )
//            }
//        }
//
        return Update(state: model, fx: fx)
    }

    private static func focus(
        state: Model,
        id: UUID
    ) -> Update<Self> {
        var model = state
        model.blocks = state.blocks.map({ block in
            block.setEditing(block.id == id) ?? block
        })
        return Update(state: model)
    }

    private static func renderFocus(
        state: Model,
        id: UUID
    ) -> Update<Self> {
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

//        let render = {
//            self.collectionView.reconfigureItems(at: [indexPath])
//        }

        return Update(state: model)
    }

    private static func blur(
        state: Model,
        id: UUID
    ) -> Update<Self> {
        var model = state
        model.blocks = state.blocks.map({ block in
            if block.id == id {
                return block.setEditing(false) ?? block
            }
            return block
        })
        return Update(state: model)
    }

    private static func renderBlur(
        state: Model,
        id: UUID
    ) -> Update<Self> {
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

//        let render = {
//            self.collectionView.reconfigureItems(at: [indexPath])
//        }

        return Update(state: model)
    }

    private static func longPress(
        state: Model,
        point: CGPoint
    ) -> Update<Self> {
        guard !state.isBlockSelectMode else {
            return Update(state: state)
        }
        Self.logger.debug("Long press triggering select mode")
//        guard let indexPath = collectionView.indexPathForItem(at: point) else {
//            let x = point.x
//            let y = point.y
//            Self.logger.debug("No block at point (\(x), \(y)). No-op.")
//            return Update(state: state)
//        }
//        let index = indexPath.row
//        guard let block = state.blocks.get(index) else {
//            Self.logger.log("No model found at index \(index). No-op.")
//            return Update(state: state)
//        }
//        let selectModeEffect = {
//            Action.enterBlockSelectMode(selecting: block.id)
//        }
        return Update(state: state)
    }

    private static func tap(
        state: Model,
        point: CGPoint
    ) -> Update<Self> {
        guard state.isBlockSelectMode else {
            return Update(state: state)
        }
        Self.logger.debug("Tap triggering block selection")
//        guard let indexPath = collectionView.indexPathForItem(at: point) else {
//            let x = point.x
//            let y = point.y
//            Self.logger.debug("No block at point (\(x), \(y)). No-op.")
//            return Update(state: state)
//        }
//        let index = indexPath.row
//        guard let block = state.blocks.get(index) else {
//            Self.logger.log("No model found at index \(index). No-op.")
//            return Update(state: state)
//        }
//        let selectModeEffect = {
//            Action.toggleSelectBlock(id: block.id)
//        }
        return Update(state: state)
    }

    private static func enterBlockSelectMode(
        state: Model,
        selecting id: UUID?
    ) -> Update<Self> {
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

//        let render = {
//            self.collectionView.reloadSections(
//                IndexSet(
//                    integer: BlockEditor.Section.blocks.rawValue
//                )
//            )
//        }

        return Update(state: model)
    }

    private static func exitBlockSelectMode(
        state: Model
    ) -> Update<Self> {
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

//        let render = {
//            self.collectionView.reloadSections(
//                IndexSet(
//                    integer: BlockEditor.Section.blocks.rawValue
//                )
//            )
//        }

        return Update(state: model)
    }

    private static func updateBlock(
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

    private static func selectBlock(
        state: Model,
        id: UUID,
        isSelected: Bool
    ) -> Update<Self> {
        guard state.isBlockSelectMode else {
            Self.logger.log("block#\(id) selected, but not in select mode. Doing nothing.")
            return Update(state: state)
        }

        guard let i = state.blockIndex(id: id) else {
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

//        let render = {
//            self.collectionView.reconfigureItems(
//                at: [
//                    IndexPath(
//                        row: i,
//                        section: BlockEditor.Section.blocks.rawValue
//                    )
//                ]
//            )
//        }

        return Update(state: model)
    }

    private static func toggleSelectBlock(
        state: Model,
        id: UUID
    ) -> Update<Self> {
        guard state.isBlockSelectMode else {
            Self.logger.log("block#\(id) selected, but not in select mode. Doing nothing.")
            return Update(state: state)
        }

        guard let i = state.blockIndex(id: id) else {
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

//        let render = {
//            self.collectionView.reconfigureItems(
//                at: [
//                    IndexPath(
//                        row: i,
//                        section: BlockEditor.Section.blocks.rawValue
//                    )
//                ]
//            )
//        }

        return Update(state: model)
    }

    private static func moveBlockUp(
        state: Model,
        id: UUID
    ) -> Update<Self> {
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

//        let render = {
//            self.collectionView.moveItem(
//                at: IndexPath(
//                    row: i,
//                    section: BlockEditor.Section.blocks.rawValue
//                ),
//                to: IndexPath(
//                    row: h,
//                    section: BlockEditor.Section.blocks.rawValue
//                )
//            )
//        }

        return Update(state: model)
    }

    private static func moveBlockDown(
        state: Model,
        id: UUID
    ) -> Update<Self> {
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

//        collectionView.moveItem(
//            at: IndexPath(
//                row: i,
//                section: BlockEditor.Section.blocks.rawValue
//            ),
//            to: IndexPath(
//                row: j,
//                section: BlockEditor.Section.blocks.rawValue
//            )
//        )
        return Update(state: model)
    }

    /// Insert markup at range within a block
    private static func insertMarkup(
        state: Model,
        id: UUID,
        selection: NSRange,
        replace: (
            String,
            Range<String.Index>
        ) -> BlockEditor.SubtextEditorMarkup.Replacement?
    ) -> Update<Self> {
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

//        let render = {
//            let indexPath = IndexPath(
//                row: i,
//                section: BlockEditor.Section.blocks.rawValue
//            )
//            self.collectionView.reconfigureItems(at: [indexPath])
//        }

        return Update(state: model)
    }

    private static func insertBold(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update<Self> {
        insertMarkup(
            state: state,
            id: id,
            selection: selection,
            replace: BlockEditor.SubtextEditorMarkup.wrapBold
        )
    }

    private static func insertItalic(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update<Self> {
        insertMarkup(
            state: state,
            id: id,
            selection: selection,
            replace: BlockEditor.SubtextEditorMarkup.wrapItalic
        )
    }

    private static func insertCode(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update<Self> {
        insertMarkup(
            state: state,
            id: id,
            selection: selection,
            replace: BlockEditor.SubtextEditorMarkup.wrapCode
        )
    }
}
