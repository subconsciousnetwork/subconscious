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
        // Is block editor enabled?
        var isEnabled = false
        /// Is editor in loading state?
        var loadingState = LoadingState.loading
        /// When was the last time the editor issued a fetch from source of truth?
        var lastLoadStarted: Date? = nil
        /// Is polling? We use this to drive autosaves.
        var isPolling = false
        
        /// Is editor saved?
        private(set) var saveState = SaveState.saved

        /// Who are we? The did that identifies our sphere.
        var ourSphere: Did?
        /// Who owns this document?
        var ownerSphere: Did?
        
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

        /// Cached transcludes for links in body
        var transcludes: [Slashlink: EntryStub] = [:]

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
        /// Handle app backgrounding, etec
        case scenePhaseChange(ScenePhase)
        /// View is ready for updates.
        /// Sent during viewDidLoad after performing first view update for
        /// initial state and subscribing to changes.
        case ready
        /// Sent from SwiftUI land when the wrapping SwiftUI view appears.
        case appear(MemoEditorDetailDescription)
        /// Start polling if needed
        case startPolling
        /// Perform a single polling step, optionally requesting another step
        case poll
        case setOurSphere(Did?)
        /// Get owner Did from peer
        case resolveOwnerSphere
        case succeedResolveOwnerSphere(_ did: Did)
        case failResolveOwnerSphere(error: String)
        /// Set document source location
        case loadEditor(
            address: Slashlink?,
            fallback: String,
            autofocus: Bool = false
        )
        case failLoadEditor(_ error: String)
        /// Reload the editor state with a new document
        case setEditor(
            detail: MemoEditorDetailResponse,
            autofocus: Bool = false
        )
        /// Reload the editor if needed, using a last-write-wins strategy.
        /// Only reloads if the provided state is newer than the current state.
        case setEditorIfNeeded(
            detail: MemoEditorDetailResponse,
            autofocus: Bool = false
        )
        /// Load related notes (backlinks)
        case fetchRelated
        case succeedFetchRelated(_ related: [EntryStub])
        case failFetchRelated(_ error: String)
        case refreshTranscludes
        case succeedRefreshTranscludes([EntryStub])
        case fetchTranscludesFor(id: UUID, slashlinks: [Slashlink])
        case succeedFetchTranscludesFor(
            id: UUID,
            fetched: [EntryStub]
        )
        case failFetchTranscludesFor(id: UUID, error: String)
        case refreshTranscludesFor(id: UUID)
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
        case textDidChange(id: UUID?, dom: Subtext, selection: NSRange)
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

        /// Handle URL in textview
        case activateLink(URL)
        /// Open link in transclude
        case requestFindLinkDetail(EntryLink)
    }
}

extension BlockEditor {
    /// Describes the state change that has happened, giving the controller
    /// the details it needs to perform that change.
    enum Change: Hashable {
        case reconfigureCollectionItems([IndexPath])
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
        
        var state: BlockEditor.Model
        var fx: Fx<Action>
        var transaction: Transaction?
        var change: BlockEditor.Change? = nil
    }
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update {
        switch action {
        case .scenePhaseChange:
            return scenePhaseChange(
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
        case .startPolling:
            return startPolling(
                state: state,
                environment: environment
            )
        case .poll:
            return poll(
                state: state,
                environment: environment
            )
        case let .setOurSphere(did):
            return setOurSphere(
                state: state,
                did: did,
                environment: environment
            )
        case .resolveOwnerSphere:
            return resolveOwnerSphere(
                state: state,
                environment: environment
            )
        case let .succeedResolveOwnerSphere(owner):
            return succeedResolveOwnerSphere(
                state: state,
                owner: owner,
                environment: environment
            )
        case let .failResolveOwnerSphere(error):
            return failResolveOwnerSphere(
                state: state,
                error: error,
                environment: environment
            )
        case let .loadEditor(address, fallback, autofocus):
            return loadEditor(
                state: state,
                address: address,
                fallback: fallback,
                autofocus: autofocus,
                environment: environment
            )
        case let .failLoadEditor(error):
            return failLoadEditor(
                state: state,
                error: error,
                environment: environment
            )
        case let .setEditor(detail, autofocus):
            return setEditor(
                state: state,
                detail: detail,
                autofocus: autofocus,
                environment: environment
            )
        case let .setEditorIfNeeded(detail, autofocus):
            return setEditorIfNeeded(
                state: state,
                detail: detail,
                autofocus: autofocus,
                environment: environment
            )
        case .fetchRelated:
            return fetchRelated(
                state: state,
                environment: environment
            )
        case let .succeedFetchRelated(related):
            return succeedFetchRelated(
                state: state,
                related: related,
                environment: environment
            )
        case let .failFetchRelated(error):
            return failFetchRelated(
                state: state,
                error: error,
                environment: environment
            )
        case .refreshTranscludes:
            return refreshTranscludes(
                state: state,
                environment: environment
            )
        case let .succeedRefreshTranscludes(transcludes):
            return succeedRefreshTranscludes(
                state: state,
                transcludes: transcludes,
                environment: environment
            )
        case let .fetchTranscludesFor(id, slashlinks):
            return fetchTranscludesFor(
                state: state,
                id: id,
                slashlinks: slashlinks,
                environment: environment
            )
        case let .succeedFetchTranscludesFor(id, fetched):
            return succeedFetchTranscludesFor(
                state: state,
                id: id,
                fetched: fetched,
                environment: environment
            )
        case let .failFetchTranscludesFor(id, error):
            return failFetchTranscludesFor(
                state: state,
                id: id,
                error: error,
                environment: environment
            )
        case let .refreshTranscludesFor(id):
            return refreshTranscludesFor(
                state: state,
                id: id,
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
        case let .textDidChange(id, dom, selection):
            return textDidChange(
                state: state,
                id: id,
                dom: dom,
                selection: selection,
                environment: environment
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
        case let .activateLink(url):
            return activateLink(
                state: state,
                url: url,
                environment: environment
            )
        case .requestFindLinkDetail(_):
            return requestFindLinkDetail(
                state: state,
                environment: environment
            )
        }
    }

    static func scenePhaseChange(
        state: Self,
        environment: Environment
    ) -> Update {
        return update(
            state: state,
            action: .autosave,
            environment: environment
        )
    }
    
    static func ready(
        state: Self,
        environment: Environment
    ) -> Update {
        return Update(state: state)
    }
    
    static func appear(
        state: Self,
        description: MemoEditorDetailDescription,
        environment: Environment
    ) -> Update {
        var model = state
        model.isEnabled = AppDefaults.standard.isBlockEditorEnabled
        
        guard model.isEnabled else {
            logger.info("Block editor is disabled. Skipping appear.")
            return Update(state: state)
        }
        
        let fetchOurSphere: Fx<Action> = Future.detached {
            Action.setOurSphere(try? await environment.noosphere.identity())
        }
        .eraseToAnyPublisher()

        let loadEditor: Fx<Action> = Just(
            Action.loadEditor(
                address: description.address,
                fallback: description.fallback
            )
        )
        .eraseToAnyPublisher()

        let startPolling: Fx<Action> = Just(
            Action.startPolling
        )
        .eraseToAnyPublisher()

        let fx: Fx<Action> = fetchOurSphere
            .merge(with: loadEditor, startPolling)
            .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }
    
    static func startPolling(
        state: Self,
        environment: Environment
    ) -> Update {
        guard state.isEnabled else {
            logger.info("Skipping polling start. Block editor is disabled.")
            return Update(state: state)
        }
        guard !state.isPolling else {
            logger.info("Skipping polling start. Already polling.")
            return Update(state: state)
        }
        var model = state
        model.isPolling = true

        let pollFx: Fx<Action> = Just(Action.poll).delay(
            for: .seconds(Config.default.pollingInterval),
            scheduler: DispatchQueue.main
        ).eraseToAnyPublisher()

        return Update(state: state, fx: pollFx)
    }
    
    static func poll(
        state: Self,
        environment: Environment
    ) -> Update {
        let pollFx: Fx<Action> = Just(Action.poll).delay(
            for: .seconds(Config.default.pollingInterval),
            scheduler: DispatchQueue.main
        ).eraseToAnyPublisher()

        let autosaveFx: Fx<Action> = Just(Action.autosave)
            .eraseToAnyPublisher()

        return Update(
            state: state,
            fx: pollFx.merge(with: autosaveFx).eraseToAnyPublisher()
        )
    }

    static func setOurSphere(
        state: Self,
        did: Did?,
        environment: Environment
    ) -> Update {
        var model = state
        model.ourSphere = did
        return Update(state: model)
    }

    static func resolveOwnerSphere(
        state: Self,
        environment: Environment
    ) -> Update {
        guard let address = state.address else {
            logger.log("Asked to resolve owner sphere but document has no address. Doing nothing.")
            return Update(state: state)
        }
        let resolveDidFx: Fx<Action> = Future.detached {
            do {
                let did = try await environment.noosphere.resolve(
                    peer: address.peer
                )
                return Action.succeedResolveOwnerSphere(did)
            } catch {
                return Action.failResolveOwnerSphere(
                    error: error.localizedDescription
                )
            }
        }
        .eraseToAnyPublisher()
        return Update(state: state, fx: resolveDidFx)
    }

    static func succeedResolveOwnerSphere(
        state: Self,
        owner: Did,
        environment: Environment
    ) -> Update {
        var model = state
        logger.info("Document owner set to \(owner)")
        model.ownerSphere = owner
        return Update(state: model)
    }

    static func failResolveOwnerSphere(
        state: Self,
        error: String,
        environment: Environment
    ) -> Update {
        logger.log("Could not resolve owner sphere from address. Error: \(error)")
        return Update(state: state)
    }

    static func loadEditor(
        state: Self,
        address: Slashlink?,
        fallback: String,
        autofocus: Bool,
        environment: Environment
    ) -> Update {
        var model = state
        model.address = address
        
        guard let address = address else {
            logger.info("Editor loaded draft (no address)")
            return Update(state: model)
        }
        
        let loadRelatedFx = Just(Action.fetchRelated)
        
        let loadDetailFx = environment.data.readMemoEditorDetailPublisher(
            address: address,
            fallback: fallback
        ).map({ detail in
            return Action.setEditorIfNeeded(
                detail: detail,
                autofocus: autofocus
            )
        }).recover({ error in
            return Action.failLoadEditor(error.localizedDescription)
        })
        
        let resolveOwnerFx: Fx<Action> = Just(Action.resolveOwnerSphere)
            .eraseToAnyPublisher()

        let fx: Fx<Action> = loadDetailFx
            .merge(with: loadRelatedFx, resolveOwnerFx)
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func failLoadEditor(
        state: Self,
        error: String,
        environment: Environment
    ) -> Update {
        let address = state.address?.description ?? "nil"
        logger.warning("Failed to load detail for \(address). Error: \(error)")
        return Update(state: state)
    }
    
    /// Set editor state, replacing whatever was previously there.
    /// This is a "force reload" that does not attempt to gracefully save the
    /// previous state. You typically want to use `setEditorIfNeeded`
    /// instead.
    static func setEditor(
        state: Self,
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
        
        let fx: Fx<Action> = Just(Action.refreshTranscludes)
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx, change: .reloadEditor)
    }
    
    /// Reload editor if needed, using a last-write-wins strategy.
    static func setEditorIfNeeded(
        state: Self,
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
                    .setEditor(detail: detail, autofocus: autofocus)
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
            action: .setEditor(detail: detail, autofocus: autofocus),
            environment: environment
        )
    }
    
    static func fetchRelated(
        state: Self,
        environment: Environment
    ) -> Update {
        guard let address = state.address else {
            logger.debug("Unable to load related. Note has no address.")
            return Update(state: state)
        }
        
        let fx: Fx<Action> = Future.detached {
            try await environment.data.readMemoBacklinks(address: address)
        }
        .map({ backlinks in
            Action.succeedFetchRelated(backlinks)
        })
        .recover({ error in
            Action.failFetchRelated(error.localizedDescription)
        })
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedFetchRelated(
        state: Self,
        related: [EntryStub],
        environment: Environment
    ) -> Update {
        let address = state.address?.description ?? "nil"
        logger.info("Loaded \(related.count) related notes for \(address)")
        var model = state
        model.appendix.related = related
        return Update(state: model)
    }
    
    static func failFetchRelated(
        state: Self,
        error: String,
        environment: Environment
    ) -> Update {
        let address = state.address?.description ?? "nil"
        logger.warning("Unable to load related notes for \(address). Error: \(error)")
        return Update(state: state)
    }
    
    static func refreshTranscludes(
        state: Self,
        environment: Environment
    ) -> Update {
        let owner = state.ownerSphere.map({ did in Peer.did(did) })
        
        // Fetch only the slashlinks that are not in the cache
        let slashlinksToFetch = state.blocks.blocks.flatMap({ block in
            block.dom?.parsedSlashlinks ?? []
        })
        .filter({ slashlink in
            state.transcludes[slashlink] == nil
        })
        .uniquing()
        
        logger.info("Fetching transcludes for \(slashlinksToFetch)")
        
        let fx: Fx<Action> = Future.detached {
            let transcludes = await environment.transclude.fetchTranscludes(
                slashlinks: slashlinksToFetch,
                owner: owner
            )
            return Action.succeedRefreshTranscludes(
                Array(transcludes.values)
            )
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedRefreshTranscludes(
        state: Self,
        transcludes: [EntryStub],
        environment: Environment
    ) -> Update {
        var model = cacheTranscludes(state: state, transcludes: transcludes)
        
        // Update all block transcludes and gather index paths
        // in a single pass.
        var blocks: [BlockEditor.BlockModel] = []
        var indexPaths: [IndexPath] = []
        for (i, block) in state.blocks.blocks.enumerated() {
            let updatedBlock = block.update { textBlock in
                textBlock.updateTranscludes(index: model.transcludes)
            }
            blocks.append(updatedBlock ?? block)
            
            let indexPath = IndexPath(
                row: i,
                section: BlockEditor.Section.blocks.rawValue
            )
            indexPaths.append(indexPath)
        }
        model.blocks.blocks = blocks
        
        return Update(
            state: model,
            change: .reconfigureCollectionItems(indexPaths)
        )
    }
    
    static func fetchTranscludesFor(
        state: Self,
        id: UUID,
        slashlinks: [Slashlink],
        environment: Environment
    ) -> Update {
        let owner = state.ownerSphere.map({ did in Peer.did(did) })
        
        // Fetch only the slashlinks that are not in the cache
        let slashlinksToFetch = slashlinks
            .filter({ slashlink in
                state.transcludes[slashlink] == nil
            })
            .uniquing()
        
        logger.info("block#\(id) fetching transcludes for \(slashlinksToFetch)")
        
        let fx: Fx<Action> = Future.detached {
            let transcludes = await environment.transclude
                .fetchTranscludes(
                    slashlinks: slashlinksToFetch,
                    owner: owner
                )
            return Action.succeedFetchTranscludesFor(
                id: id,
                fetched: Array(transcludes.values)
            )
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func cacheTranscludes(
        state: Self,
        transcludes: [EntryStub]
    ) -> Self {
        var model = state
        for transclude in transcludes {
            logger.info("Updated cached transclude for \(transclude.address)")
            model.transcludes[transclude.address] = transclude
        }
        return model
    }
    
    static func succeedFetchTranscludesFor(
        state: Self,
        id: UUID,
        fetched: [EntryStub],
        environment: Environment
    ) -> Update {
        let model = cacheTranscludes(state: state, transcludes: fetched)
        return update(
            state: model,
            action: .refreshTranscludesFor(id: id),
            environment: environment
        )
    }
    
    static func failFetchTranscludesFor(
        state: Self,
        id: UUID,
        error: String,
        environment: Environment
    ) -> Update {
        logger.warning("block#\(id) Unable to load transcludes. Error: \(error)")
        return Update(state: state)
    }
    
    static func refreshTranscludesFor(
        state: Self,
        id: UUID,
        environment: Environment
    ) -> Update {
        guard let i = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Skipping transclude refresh.")
            return Update(state: state)
        }
        
        let block = state.blocks.blocks[i]
        
        guard let block = block.update({ textBlock in
            textBlock.updateTranscludes(index: state.transcludes)
        }) else {
            Self.logger.log("block#\(id) unable to update as text block. Doing nothing.")
            return Update(state: state)
        }
        
        var model = state
        model.blocks.blocks[i] = block
        
        let indexPath = IndexPath(
            row: i,
            section: BlockEditor.Section.blocks.rawValue
        )
        
        return Update(
            state: model,
            change: .reconfigureCollectionItems([indexPath])
        )
    }
    
    static func save(
        state: Self,
        snapshot: MemoEntry?,
        environment: Environment
    ) -> Update {
        guard let snapshot = snapshot else {
            logger.log("Save given empty snapshot. Nothing to save.")
            return Update(state: state)
        }
        // If already saved, noop
        guard state.saveState != .saved else {
            logger.log("Changes already saved")
            return Update(state: state)
        }
        var model = state
        model.setSaveState(.saving)
        logger.log("Saving \(snapshot.address)")
        
        let fx: Fx<BlockEditor.Action> = environment.data
            .writeEntryPublisher(snapshot)
            .map({
                Action.succeedSave(snapshot)
            })
            .recover({ error in
                Action.failSave(
                    snapshot: snapshot,
                    error: error.localizedDescription
                )
            })
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func succeedSave(
        state: Self,
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
        state: Self,
        snapshot: MemoEntry,
        error: String,
        environment: Environment
    ) -> Update {
        var model = state
        model.setSaveState(.unsaved)
        logger.warning("Could not save \(snapshot.address). Error: \(error)")
        return Update(state: model)
    }
    
    static func autosave(
        state: Self,
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
        state: Self,
        id: UUID?,
        dom: Subtext,
        selection: NSRange,
        environment: Environment
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
            dom: dom,
            selection: selection
        )
        
        guard let block = block else {
            Self.logger.log("block#\(id) could not update block text. Doing nothing.")
            return Update(state: state)
        }
        
        model.blocks.blocks[i] = block
        
        // Mark unsaved
        model.setSaveState(.unsaved)
        
        guard let dom = block.dom else {
            logger.info("block#\(id) no DOM for this block. Skipping transclude load.")
            return Update(state: model)
        }
        
        return update(
            state: model,
            action: .fetchTranscludesFor(
                id: id,
                slashlinks: dom.parsedSlashlinks
            ),
            environment: environment
        )
    }
    
    static func didChangeSelection(
        state: Self,
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
        state: Self,
        id: UUID,
        selection nsRange: NSRange
    ) -> Update {
        guard let indexA = state.blocks.blocks.firstIndex(whereID: id) else {
            Self.logger.log("block#\(id) not found. Doing nothing.")
            return Update(state: state)
        }
        
        Self.logger.log("block#\(id) splitting at \(nsRange.location)")
        
        let blockA = state.blocks.blocks[indexA]
        
        guard let blockTextA = blockA.dom?.description else {
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
            dom: Subtext(markup: textA),
            selection: NSRange(location: nsRange.location, length: 0)
        ) else {
            Self.logger.log(
                "block#\(id) could set text. Doing nothing."
            )
            return Update(state: state)
        }
        
        var blockB = BlockEditor.TextBlockModel()
        blockB.dom = Subtext(markup: textB)
        
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
        state: Self,
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
        
        guard let blockUpText = blockUp.dom?.description else {
            Self.logger.log("block#\(id) cannot merge up into block without text. Doing nothing.")
            return Update(state: state)
        }
        
        let blockDown = state.blocks.blocks[indexDown]
        guard let blockDownText = blockDown.dom?.description else {
            Self.logger.log("block#\(id) cannot merge non-text block. Doing nothing.")
            return Update(state: state)
        }
        
        let selectionNSRange = NSRange(
            blockUpText.endIndex..<blockUpText.endIndex,
            in: blockUpText
        )
        
        guard let blockUp = blockUp.setText(
            dom: Subtext(markup: blockUpText + blockDownText),
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
        state: Self,
        id: UUID
    ) -> Update {
        var model = state
        model.blocks.blocks = state.blocks.blocks.map({ block in
            block.setEditing(block.id == id) ?? block
        })
        return Update(state: model)
    }
    
    static func renderEditing(
        state: Self,
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
            change: .reconfigureCollectionItems([indexPath])
        )
    }
    
    static func blur(
        state: Self,
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
        state: Self,
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
            change: .reconfigureCollectionItems([indexPath])
        )
    }
    
    // TODO: Reimplement
    // https://github.com/subconsciousnetwork/subconscious/issues/982
    static func longPress(
        state: Self,
        point: CGPoint
    ) -> Update {
        return Update(state: state)
    }
    
    // TODO: Reimplement
    // https://github.com/subconsciousnetwork/subconscious/issues/982
    static func tap(
        state: Self,
        point: CGPoint
    ) -> Update {
        return Update(state: state)
    }
    
    // TODO: Reimplement
    // https://github.com/subconsciousnetwork/subconscious/issues/982
    static func enterBlockSelectMode(
        state: Self,
        selecting id: UUID?
    ) -> Update {
        return Update(state: state)
    }
    
    // TODO: Reimplement
    // https://github.com/subconsciousnetwork/subconscious/issues/982
    static func exitBlockSelectMode(
        state: Self
    ) -> Update {
        return Update(state: state)
    }
    
    static func selectBlock(
        state: Self,
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
            change: .reconfigureCollectionItems([indexPath])
        )
    }
    
    static func toggleSelectBlock(
        state: Self,
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
            change: .reconfigureCollectionItems([indexPath])
        )
    }
    
    static func moveBlockUp(
        state: Self,
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
        state: Self,
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
        state: Self,
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
        
        guard let text = block.dom?.description else {
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
            dom: Subtext(markup: replacement.string),
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
            change: .reconfigureCollectionItems([indexPath])
        )
    }
    
    static func insertBold(
        state: Self,
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
        state: Self,
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
        state: Self,
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
    
    /// Handle links by parsing and then creating an FX for an onLinkTransclude
    /// action.
    static func activateLink(
        state: Self,
        url: URL,
        environment: Environment
    ) -> Update {
        guard let link = url.toSubSlashlinkLink()?.toEntryLink() else {
            logger.info("Could not parse URL as SubSlashlinkURL \(url)")
            return Update(state: state)
        }
        guard let owner = state.ownerSphere else {
            logger.info("Owner sphere identity is unknown. Doing nothing.")
            return Update(state: state)
        }

        let fx: Fx<Action> = Just(
            Action.requestFindLinkDetail(link)
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }
    
    static func requestFindLinkDetail(
        state: Self,
        environment: Environment
    ) -> Update {
        return Update(state: state)
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
