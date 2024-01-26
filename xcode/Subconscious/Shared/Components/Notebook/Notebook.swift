//
//  Notebook.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//
//  Contains Actions, update, model, and view for Notebook component.
//  Notebook is one of the tabs of our app.

import SwiftUI
import os
import ObservableStore
import Combine

// MARK: View
/// The file view for notes
struct NotebookView: View {
    /// Global shared store
    @ObservedObject var app: Store<AppModel>
    /// Local major view store
    @StateObject private var store = Store(
        state: NotebookModel(),
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: Logger(
            subsystem: Config.default.rdns,
            category: "NotebookStore"
        )
    )
    @Environment (\.colorScheme) var colorScheme

    var body: some View {
        // Give each element in this ZStack an explicit z-index.
        // This keeps transitions working correctly.
        // SwiftUI will dynamically generate z-indexes when no explicit
        // z-index is given. This can cause transitions to layer incorrectly.
        // Adding an explicit z-index fixed problems with the
        // out-transition for the search view.
        // See https://stackoverflow.com/a/58512696
        // 2021-12-16 Gordon Brander
        ZStack {
            NotebookNavigationView(
                app: app,
                store: store
            )
            .zIndex(1)
            
            if store.state.isSearchPresented {
                SearchView(
                    store: store.viewStore(
                        get: \.search,
                        tag: NotebookSearchCursor.tag
                    )
                )
                .zIndex(3)
                .transition(SearchView.presentTransition)
            }
            PinTrailingBottom(
                content: FABView(
                    action: {
                        store.send(.setSearchPresented(true))
                    }
                )
                .padding()
                .disabled(!store.state.isFabShowing)
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .zIndex(2)
            VStack {
                ToastStackView(
                    store: app.viewStore(
                        get: \.toastStack,
                        tag: ToastStackCursor.tag
                    )
                )
                Spacer()
            }
            .zIndex(3)
        }
        .onAppear {
            store.send(.appear)
        }
        /// Replay some app actions on notebook store
        .onReceive(
            app.actions.compactMap(NotebookAction.from),
            perform: store.send
        )
        /// Replay select notebook actions on app
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
        .toolbarBackground(
            colorScheme == .dark ? DeckTheme.darkBgEnd : DeckTheme.lightBgEnd,
            for: .tabBar
        )
    }
}


// MARK: Action
/// Actions for modifying state
/// For action naming convention, see
/// https://github.com/gordonbrander/subconscious/wiki/action-naming-convention
enum NotebookAction: Hashable {
    /// Tagged action for search HUD
    case search(SearchAction)
    /// Tagged action for detail stack
    case detailStack(DetailStackAction)
    
    /// Sent by `task` when the view first appears
    case appear
    /// App database is ready. We rely on parent to notify us of this event.
    case ready
    /// Emitted by database state publisher
    case databaseStateChange(DatabaseServiceState)
    
    /// Set search view presented
    case setSearchPresented(Bool)
    
    /// Refresh the state of all lists and child components by reloading
    /// from database. This also sets searches to their zero-query state.
    case refreshLists
    
    /// Read entry count from DB
    case countEntries
    /// Set the count of existing entries
    case setEntryCount(Int)
    /// Fail to get count of existing entries
    case failEntryCount(String)
    
    // List entries
    case listRecent
    case setRecent([EntryStub])
    case listRecentFailure(String)
    
    // Delete entries
    case confirmDelete(Slashlink?)
    case setConfirmDeleteShowing(Bool)
    /// Stage an entry deletion immediately before requesting.
    /// We do this for swipe-to-delete, where we must remove the entry
    /// from the list before requesting delete for the animation to work.
    case stageDeleteEntry(Slashlink)
    
    /// Note lifecycle events.
    /// `request`s are passed up to the app root
    /// `succeed`s are passed down from the app root
    case requestDeleteEntry(Slashlink?)
    case succeedDeleteEntry(Slashlink)
    case requestSaveEntry(_ entry: MemoEntry)
    case succeedSaveEntry(_ address: Slashlink, _ modified: Date)
    case requestMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case requestMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case requestUpdateAudience(_ address: Slashlink, _ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    case requestAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    case succeedAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    case requestAppendToEntry(_ address: Slashlink, _ append: String)
    case succeedAppendToEntry(_ address: Slashlink)
    
    //  Search
    /// Hit submit ("go") while focused on search field
    case submitSearch(String)
    
    // Search suggestions
    /// Search suggestion was activated
    case activatedSuggestion(Suggestion)
    
    case requestNotebookRoot
    case requestScrollToTop
    
    /// Set search query
    static func setSearch(_ query: String) -> NotebookAction {
        .search(.setQuery(query))
    }
    
    /// Set entire navigation stack
    static func setDetails(_ details: [MemoDetailDescription]) -> Self {
        .detailStack(.setDetails(details))
    }

    /// Synonym for tagged `DetailStackAction.pushDetail`
    static func pushDetail(
        _ detail: MemoDetailDescription
    ) -> Self {
        .detailStack(.pushDetail(detail))
    }

    /// Synonym for `.pushDetail` that wraps editor detail in `.editor()`
    static func pushDetail(
        _ detail: MemoEditorDetailDescription
    ) -> Self {
        .detailStack(.pushDetail(.editor(detail)))
    }

    /// Synonym for `.pushDetail` that wraps viewer detail in `.viewer()`
    static func pushDetail(
        _ detail: MemoViewerDetailDescription
    ) -> Self {
        .detailStack(.pushDetail(.viewer(detail)))
    }

    /// Synonym for tagged `DetailStackAction.pushRandomDetail`
    static func pushRandomDetail(
        autofocus: Bool
    ) -> Self {
        .detailStack(.pushRandomDetail(autofocus: autofocus))
    }
}

// MARK: Cursors and tagging functions
struct NotebookDetailStackCursor: CursorProtocol {
    typealias Model = NotebookModel
    typealias ViewModel = DetailStackModel

    static func get(state: Model) -> ViewModel {
        state.detailStack
    }

    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.detailStack = inner
        return model
    }

    static func tag(_ action: ViewModel.Action) -> NotebookModel.Action {
        switch action {
        case let .requestSaveEntry(entry):
            return .requestSaveEntry(entry)
        case let .requestDeleteEntry(entry):
            return .requestDeleteEntry(entry)
        case let .requestMoveEntry(from, to):
            return .requestMoveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .requestMergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .requestUpdateAudience(address, audience)
        case let .requestAssignNoteColor(address, color):
            return .requestAssignNoteColor(address, color)
        case let .requestAppendToEntry(address, append):
            return .requestAppendToEntry(address, append)
        case _:
            return .detailStack(action)
        }
    }
}

extension NotebookAction {
    /// Map select app actions to `NotebookAction`
    /// Used to replay select app actions on note store.
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedMigrateDatabase:
            return .ready
        case .succeedSyncLocalFilesWithDatabase:
            return .ready
        case .succeedIndexOurSphere:
            return .refreshLists
        case .succeedRecoverOurSphere:
            return .refreshLists
        case .requestNotebookRoot:
            return .requestNotebookRoot
            
        case let .succeedDeleteEntry(entry):
            return .succeedDeleteEntry(entry)
        case let .succeedSaveEntry(address, modified):
            return .succeedSaveEntry(address, modified)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        case let .succeedAssignNoteColor(address, color):
            return .succeedAssignNoteColor(address, color)
        default:
            return nil
        }
    }
}

extension AppAction {
    static func from(_ action: NotebookAction) -> Self? {
        switch action {
        case let .requestDeleteEntry(entry):
            return .deleteEntry(entry)
        case let .requestSaveEntry(entry):
            return .saveEntry(entry)
        case let .requestMoveEntry(from, to):
            return .moveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .mergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .updateAudience(address: address, audience: audience)
        case let .requestAssignNoteColor(address, color):
            return .assignColor(address: address, color: color)
        default:
            return nil
        }
    }
}

struct NotebookSearchCursor: CursorProtocol {
    static func get(state: NotebookModel) -> SearchModel {
        state.search
    }

    static func set(state: NotebookModel, inner: SearchModel) -> NotebookModel {
        var model = state
        model.search = inner
        return model
    }

    static func tag(_ action: SearchAction) -> NotebookAction {
        switch action {
        case .submitQuery(let query):
            return .submitSearch(query)
        case .activatedSuggestion(let suggestion):
            return .activatedSuggestion(suggestion)
        case .requestPresent(let isPresented):
            return .setSearchPresented(isPresented)
        default:
            return .search(action)
        }
    }
}

// MARK: Model
/// Model containing state for the notebook tab.
struct NotebookModel: ModelProtocol {
    var isDatabaseReady = false
    var isFabShowing = true
    
    /// Search HUD
    var isSearchPresented = false
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
    /// Contains notebook detail panels
    var detailStack = DetailStackModel()
    var details: [MemoDetailDescription] {
        detailStack.details
    }
    
    /// Count of entries
    var entryCount: Int? = nil
    
    ///  Recent entries (nil means "hasn't been loaded from DB")
    var recent: [EntryStub]? = nil
    
    var feed: [EntryStub]? = nil
    
    //  Note deletion action sheet
    /// Delete confirmation action sheet
    var entryToDelete: Slashlink? = nil
    /// Delete confirmation action sheet
    var isConfirmDeleteShowing = false
    
    // MARK: Update
    // !!!: Combine publishers can cause segfaults in Swift compiler
    // Combine publishers have complex types and must be marked up carefully
    // to avoid frequent segfaults in Swift compiler due to type inference
    // (as of 2022-01-14).
    //
    // We found the following mitigation/solution:
    // - Mark publisher variables with explicit type annotations.
    // - Beware Publishers.Merge and variants. Use publisher.merge instead.
    //   Publishers.Merge produces a more complex type signature, and this seems
    //   to be what was crashing the Swift compiler.
    //
    // 2022-01-14 Gordon Brander
    /// AppUpdate is a namespace where we keep the main app update function,
    /// as well as the sub-update functions it calls out to.
    
    /// Main update function
    static func update(
        state: NotebookModel,
        action: NotebookAction,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        switch action {
        case .search(let action):
            return NotebookSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case let .detailStack(action):
            return NotebookDetailStackCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case .ready:
            return ready(
                state: state,
                environment: environment
            )
        case .databaseStateChange(let databaseState):
            return databaseStateChange(
                state: state,
                environment: environment,
                databaseState: databaseState
            )
        case .setSearchPresented(let isPresented):
            return setSearchPresented(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .refreshLists:
            return refreshLists(state: state, environment: environment)
        case .countEntries:
            return countEntries(
                state: state,
                environment: environment
            )
        case .setEntryCount(let count):
            return setEntryCount(
                state: state,
                environment: environment,
                count: count
            )
        case .failEntryCount(let error):
            logger.warning("Failed to count entries: \(error)")
            return Update(state: state)
        case .listRecent:
            return listRecent(
                state: state,
                environment: environment
            )
        case let .setRecent(entries):
            var model = state
            model.recent = entries
            return Update(state: model)
        case let .listRecentFailure(error):
            logger.warning(
                "Failed to list recent entries: \(error)"
            )
            return Update(state: state)
        case let .confirmDelete(address):
            return confirmDelete(
                state: state,
                environment: environment,
                address: address
            )
        case let .setConfirmDeleteShowing(isShowing):
            return setConfirmDeleteShowing(
                state: state,
                environment: environment,
                isShowing: isShowing
            )
        case let .stageDeleteEntry(address):
            return stageDeleteEntry(
                state: state,
                environment: environment,
                address: address
            )
        case let .succeedSaveEntry(address, modified):
            return succeedSaveEntry(
                state: state,
                environment: environment,
                address: address,
                modified: modified
            )
        case .succeedDeleteEntry(let address):
            return succeedDeleteEntry(
                state: state,
                environment: environment,
                address: address
            )
        case let .succeedMoveEntry(from, to):
            return succeedMoveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case let .succeedMergeEntry(parent, child):
            return succeedMergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case let .succeedUpdateAudience(receipt):
            return succeedUpdateAudience(
                state: state,
                environment: environment,
                receipt: receipt
            )
        case let .succeedAssignNoteColor(address, color):
            return succeedAssignNoteColor(
                state: state,
                environment: environment,
                address: address,
                color: color
            )
        case .submitSearch(let query):
            return submitSearch(
                state: state,
                environment: environment,
                query: query
            )
        case let .activatedSuggestion(suggestion):
            return NotebookDetailStackCursor.update(
                state: state,
                action: DetailStackAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .requestNotebookRoot:
            return requestNotebookRoot(
                state: state,
                environment: environment
            )
        case let .succeedAppendToEntry(address):
            return succeedAppendToEntry(state: state, environment: environment, address: address)
        case .requestDeleteEntry, .requestSaveEntry, .requestMoveEntry,
                .requestMergeEntry, .requestUpdateAudience, .requestScrollToTop,
                .requestAssignNoteColor, .requestAppendToEntry:
            return Update(state: state)
        }
    }
    
    // Logger for actions
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "notebook"
    )
    
    /// Just before view appears (sent by task)
    static func appear(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        // Skip refreshing the view if we're still starting up
        guard state.isDatabaseReady else {
            return Update(state: state)
        }
        
        return update(
            state: state,
            action: .refreshLists,
            environment: environment
        )
    }
    
    /// View is ready
    static func ready(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        return update(
            state: state,
            action: .refreshLists,
            environment: environment
        )
    }
    
    /// Handle database state changes
    static func databaseStateChange(
        state: NotebookModel,
        environment: AppEnvironment,
        databaseState: DatabaseServiceState
    ) -> Update<NotebookModel> {
        var model = state
        // If database is not ready, set ready to false and do nothing
        guard databaseState == .ready else {
            model.isDatabaseReady = false
            return Update(state: model)
        }
        // If database is ready, set ready and send down ready action.
        model.isDatabaseReady = true
        return update(
            state: model,
            action: .ready,
            environment: environment
        )
    }
    
    /// Set search presented flag
    static func setSearchPresented(
        state: NotebookModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<NotebookModel> {
        var model = state
        model.isSearchPresented = isPresented
        return Update(state: model)
    }
    
    /// Refresh all lists in the notebook tab from database.
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshLists(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        return NotebookModel.update(
            state: state,
            actions: [
                .search(.refreshSuggestions),
                .countEntries,
                .listRecent
            ],
            environment: environment
        )
    }
    
    /// Read entry count from db
    static func countEntries(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data
            .countMemosPublisher()
            .map({ count in
                NotebookAction.setEntryCount(count)
            })
            .recover({ error in
                NotebookAction.failEntryCount(error.localizedDescription)
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    /// Set entry count
    static func setEntryCount(
        state: NotebookModel,
        environment: AppEnvironment,
        count: Int
    ) -> Update<NotebookModel> {
        var model = state
        model.entryCount = count
        return Update(state: model)
    }
    
    static func listRecent(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data.listRecentMemosPublisher()
            .map({ entries in
                NotebookAction.setRecent(entries)
            })
            .catch({ error in
                Just(
                    .listRecentFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    static func confirmDelete(
        state: NotebookModel,
        environment: AppEnvironment,
        address: Slashlink?
    ) -> Update<NotebookModel> {
        guard let address = address else {
            logger.log(
                "Delete confirmation flow passed nil slug. Doing nothing."
            )
            var model = state
            // Nil out entryToDelete, if any
            model.entryToDelete = nil
            return Update(state: model)
        }
        var model = state
        model.entryToDelete = address
        model.isConfirmDeleteShowing = true
        return Update(state: model)
    }
    
    static func setConfirmDeleteShowing(
        state: NotebookModel,
        environment: AppEnvironment,
        isShowing: Bool
    ) -> Update<NotebookModel> {
        var model = state
        model.isConfirmDeleteShowing = isShowing
        // Reset entry to delete if we're dismissing the confirmation
        // dialog.
        if isShowing == false {
            model.entryToDelete = nil
        }
        return Update(state: model)
    }
    
    /// Delete entry with `slug`
    static func stageDeleteEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        address: Slashlink
    ) -> Update<NotebookModel> {
        var model = state
        
        // If we have recent entries, and can find this slug,
        // immediately remove it from recent entries without waiting
        // for database success to come back.
        // This gives us the desired effect of swiping and having it removed.
        // It'll come back if database failed somehow.
        // Note it is possible that the slug exists, but is not in this list
        // so we don't treat the list as a source of truth.
        // We're just updating the view ahead of what the source of truth
        // might tell us.
        // 2022-02-18 Gordon Brander
        if
            var recent = model.recent,
            let index = recent.firstIndex(where: {
                stub in stub.address == address
            })
        {
            recent.remove(at: index)
            model.recent = recent
        }
        
        let fx: Fx<NotebookAction> = Just(.requestDeleteEntry(address)).eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
            .animation(.default)
    }
    
    /// Entry delete succeeded
    static func succeedDeleteEntry(
        state: Self,
        environment: Environment,
        address: Slashlink
    ) -> Update<NotebookModel> {
        logger.log(
            "Memo was deleted",
            metadata: [
                "address": address.description
            ]
        )
        return update(
            state: state,
            actions: [
                .detailStack(.succeedDeleteEntry(address)),
                .refreshLists
            ],
            environment: environment
        )
    }

    static func succeedSaveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        address: Slashlink,
        modified: Date
    ) -> Update<NotebookModel> {
        // Just refresh note after save, for now.
        // This reorders list by modified.
        return update(
            state: state,
            actions: [
                .refreshLists,
                .detailStack(.succeedSaveEntry(address, modified))
            ],
            environment: environment
        )
    }

    static func succeedMoveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: Slashlink,
        to: Slashlink
    ) -> Update<NotebookModel> {
        return update(
            state: state,
            actions: [
                .detailStack(.succeedMoveEntry(from: from, to: to)),
                .refreshLists
            ],
            environment: environment
        )
    }

    static func succeedMergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        parent: Slashlink,
        child: Slashlink
    ) -> Update<NotebookModel> {
        return update(
            state: state,
            actions: [
                .detailStack(.succeedMergeEntry(parent: parent, child: child)),
                .refreshLists
            ],
            environment: environment
        )
    }

    static func succeedUpdateAudience(
        state: NotebookModel,
        environment: AppEnvironment,
        receipt: MoveReceipt
    ) -> Update<NotebookModel> {
        return update(
            state: state,
            actions: [
                .detailStack(.succeedUpdateAudience(receipt)),
                .refreshLists
            ],
            environment: environment
        )
    }
    
    static func succeedAssignNoteColor(
        state: NotebookModel,
        environment: AppEnvironment,
        address: Slashlink,
        color: ThemeColor
    ) -> Update<NotebookModel> {
        return update(
            state: state,
            actions: [
                .detailStack(.succeedAssignNoteColor(address, color)),
                .refreshLists
            ],
            environment: environment
        )
    }
    
    static func succeedAppendToEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        address: Slashlink
    ) -> Update<Self> {
        return update(
            state: state,
            actions: [
                .detailStack(.succeedAppendToEntry(address)),
                .refreshLists
            ],
            environment: environment
        )
    }

    /// Submit a search query (typically by hitting "go" on keyboard)
    static func submitSearch(
        state: NotebookModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<NotebookModel> {
        // Duration of keyboard animation
        let duration = Duration.keyboard
        let delay = duration + 0.03
        
        /// We intercepted this action, so create an Fx to forward it down.
        let update = NotebookModel.update(
            state: state,
            action: .search(.submitQuery(query)),
            environment: environment
        )
        
        // Derive slug. If we can't (e.g. invalid query such as empty string),
        // just hide the search HUD and do nothing.
        guard
            let address = Slug(formatting: query)?.toLocalSlashlink()
        else {
            logger.log(
                "Query could not be converted to link: \(query)"
            )
            return update
        }
        
        // Request detail AFTER animaiton completes
        let fx: Fx<NotebookAction> = Just(
            NotebookAction.pushDetail(
                MemoEditorDetailDescription(
                    address: address,
                    fallback: query
                )
            )
        )
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
        
        return update.mergeFx(fx)
    }
    
    static func requestNotebookRoot(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        if state.details.isEmpty {
            let fx: Fx<NotebookAction> = Just(.requestScrollToTop).eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        }
        
        return NotebookDetailStackCursor.update(
            state: state,
            action: .setDetails([]),
            environment: environment
        )
    }
}
