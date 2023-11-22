//
//  BlockStackEditorModle.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/28/23.
//

import Foundation
import os
import SwiftUI
import Combine
import ObservableStore

extension BlockEditor {
    // MARK: Model
    struct Model: Hashable {
        /// Time interval after which a load is considered stale, and should be
        /// reloaded to make sure it is fresh.
        static let loadStaleInterval: TimeInterval = 0.2
        
        static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditor.Model"
        )
        
        /// Create a BlockEditor "draft" document.
        /// A draft is a document with a heading block and nothing else.
        static func draft() -> Self {
            Model(
                blocks: BlocksModel(
                    blocks: [
                        BlockModel.heading(TextBlockModel())
                    ]
                )
            )
        }
        
        /// Is editor in loading state?
        var loadingState = LoadingState.loading
        /// When was the last time the editor issued a fetch from source of truth?
        var lastLoadStarted: Date? = nil
        
        /// Is editor saved?
        private(set) var saveState = SaveState.saved
        
        var address: Slashlink? = nil
        var contentType = ContentType.subtext
        var fileExtension = ContentType.subtext.fileExtension
        /// Created date
        var created: Date? = nil
        /// Last modified date.
        var modified: Date? = nil
        var additionalHeaders: [Header] = []
        
        var blocks: BlocksModel = BlocksModel()
        var appendix = RelatedModel()

        mutating func setSaveState(_ state: SaveState) {
            if self.saveState == state {
                return
            }
            self.saveState = state
            Self.logger.log("Editor save state: \(String(describing: state))")
        }
    }
}

extension BlockEditor {
    // MARK: Actions
    enum Action {
        /// Sent once when store is created
        case start
        /// View is ready for updates.
        /// Sent during viewDidLoad after performing first view update for
        /// initial state and subscribing to changes.
        case ready
        /// Sent from SwiftUI land when the wrapping SwiftUI view appears.
        case appear(MemoEditorDetailDescription)
        /// Set document source location
        case setAddress(Slashlink?)
        /// Reload the editor state with a new document
        case reloadEditor(
            detail: MemoEditorDetailResponse,
            autofocus: Bool = false
        )
        /// Reload the editor if needed, using a last-write-wins strategy.
        /// Only reloads if the provided state is newer than the current state.
        case reloadEditorIfNeeded(
            detail: MemoEditorDetailResponse,
            autofocus: Bool = false
        )
        case failReloadEditor(_ error: String)
        /// Save a snapshot
        case save(_ snapshot: MemoEntry?)
        case succeedSave(_ snapshot: MemoEntry)
        case failSave(
            snapshot: MemoEntry,
            error: String
        )
        /// Autosave whatever is in the editor.
        /// Sent at some interval to save draft state.
        case autosave
        case textDidChange(id: UUID?, text: String, selection: NSRange)
        case didChangeSelection(id: UUID, selection: NSRange)
        case splitBlock(id: UUID, selection: NSRange)
        case mergeBlockUp(id: UUID)
        /// Record a focus from the user
        case editing(id: UUID)
        /// Force editing mode
        case renderEditing(id: UUID)
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

extension BlockEditor {
    /// Describes the state change that has happened, giving the controller
    /// the details it needs to perform that change.
    enum Change: Hashable {
        case reconfigureCollectionItem(IndexPath)
        case reloadEditor
        case moveBlock(
            at: IndexPath,
            to: IndexPath
        )
        case splitBlock(
            reconfigure: IndexPath,
            insert: IndexPath,
            requestEditing: BlockModel.ID
        )
        case mergeBlockUp(
            reconfigure: IndexPath,
            delete: IndexPath,
            requestEditing: BlockModel.ID
        )
    }
}

// MARK: Controller
extension BlockEditor.Model: ModelProtocol {
    typealias Model = BlockEditor.Model
    typealias Action = BlockEditor.Action
    typealias Environment = AppEnvironment
    
    struct Update: UpdateProtocol {
        init(
            state: BlockEditor.Model,
            fx: ObservableStore.Fx<BlockEditor.Action>,
            transaction: Transaction?
        ) {
            self.state = state
            self.fx = fx
            self.transaction = transaction
        }
        
        init(
            state: BlockEditor.Model,
            fx: Fx<BlockEditor.Action> = Empty(completeImmediately: true)
                .eraseToAnyPublisher(),
            transaction: Transaction? = nil,
            change: BlockEditor.Change? = nil
        ) {
            self.state = state
            self.fx = fx
            self.transaction = transaction
            self.change = change
        }
        
        var state: Model
        var fx: Fx<Action>
        var transaction: Transaction?
        var change: BlockEditor.Change? = nil
    }

    static func update(
        state: Model,
        action: Action,
        environment: Environment
    ) -> Update {
        switch action {
        case .start:
            return start(
                state: state,
                environment: environment
            )
        case .ready:
            return ready(
                state: state,
                environment: environment
            )
        case let .appear(description):
            return appear(
                state: state,
                description: description,
                environment: environment
            )
        case let .setAddress(address):
            return setAddress(
                state: state,
                address: address,
                environment: environment
            )
        case let .reloadEditor(detail, autofocus):
            return reloadEditor(
                state: state,
                detail: detail,
                autofocus: autofocus,
                environment: environment
            )
        case let .reloadEditorIfNeeded(detail, autofocus):
            return reloadEditorIfNeeded(
                state: state,
                detail: detail,
                autofocus: autofocus,
                environment: environment
            )
        case let .failReloadEditor(error):
            return failReloadEditor(
                state: state,
                error: error,
                environment: environment
            )
        case let .save(snapshot):
            return save(
                state: state,
                snapshot: snapshot,
                environment: environment
            )
        case let .succeedSave(snapshot):
            return succeedSave(
                state: state,
                snapshot: snapshot,
                environment: environment
            )
        case let .failSave(snapshot, error):
            return failSave(
                state: state,
                snapshot: snapshot,
                error: error,
                environment: environment
            )
        case .autosave:
            return autosave(
                state: state,
                environment: environment
            )
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
        case let .editing(id):
            return editing(
                state: state,
                id: id
            )
        case let .renderEditing(id):
            return renderEditing(
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
    
    static func start(
        state: Model,
        environment: Model.Environment
    ) -> Update {
        /// Poll and autosave until this store is destroyed.
        let pollFx: Fx<Model.Action> = AppEnvironment
            .poll(every: Config.default.pollingInterval)
            .map({ _ in .autosave })
            .eraseToAnyPublisher()
        return Update(state: state, fx: pollFx)
    }

    static func ready(
        state: Model,
        environment: Model.Environment
    ) -> Update {
        return Update(state: state)
    }
    
    static func appear(
        state: Model,
        description: MemoEditorDetailDescription,
        environment: Model.Environment
    ) -> Update {
        return setAddress(
            state: state,
            address: description.address,
            fallback: description.fallback,
            environment: environment
        )
    }
    
    static func setAddress(
        state: Model,
        address: Slashlink?,
        fallback: String = "",
        autofocus: Bool = false,
        environment: Environment
    ) -> Update {
        var model = state
        model.address = address

        guard let address = address else {
            return Update(state: model)
        }

        let fx: Fx<Action> = environment.data.readMemoEditorDetailPublisher(
            address: address,
            fallback: fallback
        )
        .map({ detail in
            return Action.reloadEditor(
                detail: detail,
                autofocus: autofocus
            )
        })
        .recover({ error in
            return Action.failReloadEditor(error.localizedDescription)
        })
        .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }
    
    /// Reload editor, replacing whatever was previously there.
    /// This is a "force reload" that does not attempt to gracefully save the
    /// previous state. You typically want to use `reloadEditorIfNeeded`
    /// instead.
    static func reloadEditor(
        state: Model,
        detail: MemoEditorDetailResponse,
        autofocus: Bool = false,
        environment: Environment
    ) -> Update {
        var model = state
        // Finished loading. We have the data.
        model.loadingState = .loaded
        model.setSaveState(detail.saveState)
        model.address = detail.entry.address
        model.created = detail.entry.contents.created
        model.modified = detail.entry.contents.modified
        // Get content type from loaded file, falling back to subtext
        // if not provided.
        model.contentType = (
            ContentType(rawValue: detail.entry.contents.contentType) ??
            ContentType.subtext
        )
        model.fileExtension = detail.entry.contents.fileExtension
        model.additionalHeaders = detail.entry.contents.additionalHeaders
        model.blocks = BlockEditor.BlocksModel(detail.entry.contents.body)
        return Update(state: model, change: .reloadEditor)
    }
    
    /// Reload editor if needed, using a last-write-wins strategy.
    static func reloadEditorIfNeeded(
        state: Model,
        detail: MemoEditorDetailResponse,
        autofocus: Bool = false,
        environment: Environment
    ) -> Update {
        var model = state
        // Finished loading. We have the data.
        model.loadingState = .loaded

        // Slugs don't match. Different entries.
        // Save current state and set new detail.
        guard (state.address == detail.entry.address) else {
            let snapshot = MemoEntry(model)
            logger.log("Block editor given new document. Saving current state and reloading with new document.")
            return update(
                state: model,
                actions: [
                    .save(snapshot),
                    .reloadEditor(detail: detail, autofocus: autofocus)
                ],
                environment: environment
            )
        }

        let modified = state.modified ?? Date.distantPast

        // Make sure detail is newer than current editor modified state.
        // Otherwise do nothing.
        guard detail.entry.contents.modified > modified else {
            logger.log("Block editor state is newer than loaded document. Preferring editor state.")
            return Update(state: state)
        }
        
        logger.log("Block editor given document that is newer than editor's last modified date. Considering editor content stale and reloading.")
        return update(
            state: model,
            action: .reloadEditor(detail: detail, autofocus: autofocus),
            environment: environment
        )
    }
    
    static func failReloadEditor(
        state: Model,
        error: String,
        environment: Environment
    ) -> Update {
        let address = state.address?.description ?? "nil"
        logger.log("Failed to load detail for \(address). Error: \(error)")
        return Update(state: state)
    }
    
    static func save(
        state: Model,
        snapshot: MemoEntry?,
        environment: Environment
    ) -> Update {
        guard let snapshot = snapshot else {
            logger.log("Nothing to save")
            return Update(state: state)
        }
        // If already saved, noop
        guard state.saveState != .saved else {
            logger.log("Already saved")
            return Update(state: state)
        }
        var model = state
        model.setSaveState(.saving)
        logger.log("Saving \(snapshot.address)")

        let fx: Fx<BlockEditor.Action> = environment.data
            .writeEntryPublisher(snapshot)
            .map({
                .succeedSave(snapshot)
            })
            .recover({ error in
                .failSave(
                    snapshot: snapshot,
                    error: error.localizedDescription
                )
            })
            .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }

    static func succeedSave(
        state: Model,
        snapshot: MemoEntry,
        environment: Environment
    ) -> Update {
        logger.log("Saved \(snapshot.address)")
        
        var model = state
        
        // If editor state is still the state we invoked save with,
        // then mark the current editor state as "saved".
        // We check before setting in case changes happened between the
        // time we invoked save and the time it completed.
        // If changes did happen in that time, we want to leave the current
        // state alone, giving future saves a chance to pick up and save the
        // new changes.
        // 2023-11-22 Gordon Brander
        if state.saveState == .saving {
            let current = MemoEntry(state)
            if (snapshot == current) {
                model.setSaveState(.saved)
            }
        }
        
        return Update(state: model)
    }
    
    static func failSave(
        state: Model,
        snapshot: MemoEntry,
        error: String,
        environment: Environment
    ) -> Update {
        var model = state
        model.setSaveState(.unsaved)
        logger.log("Could not save \(snapshot.address). Error: \(error)")
        return Update(state: model)
    }
    
    static func autosave(
        state: Model,
        environment: Environment
    ) -> Update {
        let snapshot = MemoEntry(state)
        return save(
            state: state,
            snapshot: snapshot,
            environment: environment
        )
    }

    static func textDidChange(
        state: Model,
        id: UUID?,
        text: String,
        selection: NSRange
    ) -> Update {
        guard let id = id else {
            Self.logger.log("No block id. Doing nothing.")
            return Update(state: state)
        }
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        var model = state
        
        let block = state.blocks.blocks[i].setText(
            text: text,
            selection: selection
        )
        
        guard let block = block else {
            Self.logger.log("block#\(id) could not update block text. Doing nothing.")
            return Update(state: state)
        }
        
        model.blocks.blocks[i] = block

        // Mark unsaved
        model.setSaveState(.unsaved)
        
        return Update(state: model)
    }
    
    static func didChangeSelection(
        state: Model,
        id: UUID,
        selection: NSRange
    ) -> Update {
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        var model = state
        guard let block = state.blocks.blocks[i].setSelection(
            selection: selection
        ) else {
            Self.logger.log("block#\(id) could not update block selection. Doing nothing.")
            return Update(state: state)
        }
        model.blocks.blocks[i] = block
        return Update(state: model)
    }
    
    static func splitBlock(
        state: Model,
        id: UUID,
        selection nsRange: NSRange
    ) -> Update {
        guard let indexA = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        Self.logger.log("block#\(id) splitting at \(nsRange.location)")
        
        let blockA = state.blocks.blocks[indexA]
        
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
        
        let indexB = state.blocks.blocks.index(after: indexA)
        var model = state
        model.blocks.blocks[indexA] = blockA
        model.blocks.blocks.insert(
            .text(blockB),
            at: indexB
        )
        
        let indexPathB = IndexPath(
            row: indexB,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        let indexPathA = IndexPath(
            row: indexA,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        // Mark unsaved
        model.setSaveState(.unsaved)
        
        return Update(
            state: model,
            change: .splitBlock(
                reconfigure: indexPathA,
                insert: indexPathB,
                requestEditing: blockB.id
            )
        )
    }
    
    static func mergeBlockUp(
        state: Model,
        id: UUID
    ) -> Update {
        guard let indexDown = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        guard indexDown > 0 else {
            Self.logger.log("block#\(id) is first block. Skipping merge up.")
            return Update(state: state)
        }
        Self.logger.log("block#\(id) merging up")
        
        let indexUp = state.blocks.blocks.index(before: indexDown)
        let blockUp = state.blocks.blocks[indexUp]
        
        guard let blockUpText = blockUp.text else {
            Self.logger.log("block#\(id) cannot merge up into block without text. Doing nothing.")
            return Update(state: state)
        }
        
        let blockDown = state.blocks.blocks[indexDown]
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
        model.blocks.blocks[indexUp] = blockUp
        model.blocks.blocks.remove(at: indexDown)
        
        let indexPathUp = IndexPath(
            row: indexUp,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        let indexPathDown = IndexPath(
            row: indexDown,
            section: BlockEditor.Section.blocks.rawValue
        )

        // Mark unsaved
        model.setSaveState(.unsaved)

        return Update(
            state: model,
            change: .mergeBlockUp(
                reconfigure: indexPathUp,
                delete: indexPathDown,
                requestEditing: blockUp.id
            )
        )
    }
    
    static func editing(
        state: Model,
        id: UUID
    ) -> Update {
        var model = state
        model.blocks.blocks = state.blocks.blocks.map({ block in
            block.setEditing(block.id == id) ?? block
        })
        return Update(state: model)
    }
    
    static func renderEditing(
        state: Model,
        id: UUID
    ) -> Update {
        guard let index = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) no block found with ID. Doing nothing.")
            return Update(state: state)
        }
        
        let indexPath = IndexPath(
            row: index,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        var model = state
        model.blocks.blocks = state.blocks.blocks.map({ block in
            block.setEditing(block.id == id) ?? block
        })
        
        return Update(
            state: model,
            change: .reconfigureCollectionItem(indexPath)
        )
    }
    
    static func blur(
        state: Model,
        id: UUID
    ) -> Update {
        var model = state
        model.blocks.blocks = state.blocks.blocks.map({ block in
            if block.id == id {
                return block.setEditing(false) ?? block
            }
            return block
        })
        return Update(state: model)
    }
    
    static func renderBlur(
        state: Model,
        id: UUID
    ) -> Update {
        guard let index = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) no block found with ID. Doing nothing.")
            return Update(state: state)
        }
        
        let indexPath = IndexPath(
            row: index,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        var model = state
        model.blocks.blocks = state.blocks.blocks.map({ block in
            if block.id == id {
                return block.setEditing(false) ?? block
            }
            return block
        })
        
        return Update(
            state: model,
            change: .reconfigureCollectionItem(indexPath)
        )
    }

    // TODO: re-implement
    static func longPress(
        state: Model,
        point: CGPoint
    ) -> Update {
//        guard !state.isBlockSelectMode else {
//            return Update(state: state)
//        }
//        Self.logger.debug("Long press triggering select mode")
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
//        return Update(state: state, effects: [selectModeEffect])
        return Update(state: state)
    }

    // TODO: Reimplement
    static func tap(
        state: Model,
        point: CGPoint
    ) -> Update {
//        guard state.isBlockSelectMode else {
//            return Update(state: state)
//        }
//        Self.logger.debug("Tap triggering block selection")
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

    // TODO: Reimplement
    static func enterBlockSelectMode(
        state: Model,
        selecting id: UUID?
    ) -> Update {
//        var model = state
//
//        model.isBlockSelectMode = true
//        model.blocks = state.blocks.map({ block in
//            let updated = block.update { block in
//                var block = block
//                block.isBlockSelectMode = true
//                block.isBlockSelected = block.id == id
//                return block
//            }
//            return updated ?? block
//        })
//
//        let render = {
//            self.collectionView.reloadSections(
//                IndexSet(
//                    integer: BlockEditor.Section.blocks.rawValue
//                )
//            )
//        }
//
        return Update(state: state)
    }

    // TODO: Reimplement
    static func exitBlockSelectMode(
        state: Model
    ) -> Update {
//        var model = state
//
//        model.isBlockSelectMode = false
//        model.blocks = state.blocks.map({ block in
//            let updated = block.update { block in
//                var block = block
//                block.isBlockSelectMode = false
//                block.isBlockSelected = false
//                return block
//            }
//            return updated ?? block
//        })
//
//        let render = {
//            self.collectionView.reloadSections(
//                IndexSet(
//                    integer: BlockEditor.Section.blocks.rawValue
//                )
//            )
//        }
//
        return Update(state: state)
    }
    
    static func selectBlock(
        state: Model,
        id: UUID,
        isSelected: Bool
    ) -> Update {
        guard state.blocks.isBlockSelectMode else {
            Self.logger.log("block#\(id) selected, but not in select mode. Doing nothing.")
            return Update(state: state)
        }
        
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            return Update(state: state)
        }
        
        var model = state
        let block = model.blocks.blocks[i]
        let updatedBlock = block.setBlockSelected(isSelected) ?? block

        guard block != updatedBlock else {
            Self.logger.debug("Block selection state did not change.")
            return Update(state: state)
        }
        model.blocks.blocks[i] = updatedBlock
        
        let indexPath = IndexPath(
            row: i,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        return Update(
            state: model,
            change: .reconfigureCollectionItem(indexPath)
        )
    }

    static func toggleSelectBlock(
        state: Model,
        id: UUID
    ) -> Update {
        guard state.blocks.isBlockSelectMode else {
            Self.logger.log("block#\(id) selected, but not in select mode. Doing nothing.")
            return Update(state: state)
        }
        
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            return Update(state: state)
        }
        
        var model = state
        let block = model.blocks.blocks[i]
        let isSelected = block.isBlockSelected
        let updatedBlock = block.setBlockSelected(!isSelected) ?? block

        guard block != updatedBlock else {
            Self.logger.debug("Block selection state did not change.")
            return Update(state: state)
        }
        model.blocks.blocks[i] = updatedBlock
        
        let indexPath = IndexPath(
            row: i,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        return Update(
            state: model,
            change: .reconfigureCollectionItem(indexPath)
        )
    }

    static func moveBlockUp(
        state: Model,
        id: UUID
    ) -> Update {
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        var blocksArray = state.blocks.blocks
        
        guard i > blocksArray.startIndex else {
            Self.logger.log("block#\(id) can't move up first block. Doing nothing.")
            return Update(state: state)
        }
        
        let h = blocksArray.index(before: i)
        blocksArray.swapAt(h, i)
        var model = state
        model.blocks.blocks = blocksArray
        
        let atIndexPath = IndexPath(
            row: i,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        let toIndexPath = IndexPath(
            row: h,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        // Mark unsaved
        model.setSaveState(.unsaved)
        
        return Update(
            state: model,
            change: .moveBlock(at: atIndexPath, to: toIndexPath)
        )
    }
    
    static func moveBlockDown(
        state: Model,
        id: UUID
    ) -> Update {
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        var blocksArray = state.blocks.blocks
        
        let lastItemIndex = blocksArray.index(before: blocksArray.endIndex)
        guard i < lastItemIndex else {
            Self.logger.log("block#\(id) can't move down last block. Doing nothing.")
            return Update(state: state)
        }
        
        let j = blocksArray.index(after: i)
        blocksArray.swapAt(i, j)
        
        var model = state
        model.blocks.blocks = blocksArray
        
        let atIndexPath = IndexPath(
            row: i,
            section: BlockEditor.Section.blocks.rawValue
        )

        let toIndexPath = IndexPath(
            row: j,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        // Mark unsaved
        model.setSaveState(.unsaved)
        
        return Update(
            state: model,
            change: .moveBlock(at: atIndexPath, to: toIndexPath)
        )
    }
        
    /// Insert markup at range within a block
    static func insertMarkup(
        state: Model,
        id: UUID,
        selection: NSRange,
        replace: (
            String,
            Range<String.Index>
        ) -> BlockEditor.SubtextEditorMarkup.Replacement?
    ) -> Update {
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        let block = state.blocks.blocks[i]

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
        model.blocks.blocks[i] = block
        
        let indexPath = IndexPath(
            row: i,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        // Mark unsaved
        model.setSaveState(.unsaved)
        
        return Update(
            state: model,
            change: .reconfigureCollectionItem(indexPath)
        )
    }

    static func insertBold(
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
    
    static func insertItalic(
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
    
    static func insertCode(
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

extension MemoEntry {
    init?(_ model: BlockEditor.Model) {
        guard let address = model.address else {
            return nil
        }
        let now = Date.now
        self.init(
            address: address,
            contents: Memo(
                contentType: model.contentType.rawValue,
                created: model.created ?? now,
                modified: model.modified ?? now,
                fileExtension: model.contentType.fileExtension,
                additionalHeaders: model.additionalHeaders,
                body: model.blocks.description
            )
        )
    }
}
