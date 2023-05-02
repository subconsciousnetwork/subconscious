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

//  MARK: View
/// The file view for notes
struct NotebookView: View {
    /// Global shared store
    @ObservedObject var app: Store<AppModel>
    /// Local major view store
    @StateObject private var store = Store(
        state: NotebookModel(),
        environment: AppEnvironment.default
    )

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
                    state: store.state.search,
                    send: Address.forward(
                        send: store.send,
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
        }
        .onAppear {
            store.send(.appear)
        }
        /// Wire up local store to respond to some events at app level
        .onReceive(
            app.actions.compactMap(NotebookAction.from),
            perform: store.send
        )
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            NotebookModel.logger.debug("[action] \(message)")
        }
    }
}


//  MARK: Action
/// Actions for modifying state
/// For action naming convention, see
/// https://github.com/gordonbrander/subconscious/wiki/action-naming-convention
enum NotebookAction {
    /// Tagged action for search HUD
    case search(SearchAction)
    
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
    case failEntryCount(Error)
    
    // List entries
    case listRecent
    case setRecent([EntryStub])
    case listRecentFailure(String)
    
    // Delete entries
    case confirmDelete(MemoAddress?)
    case setConfirmDeleteShowing(Bool)
    /// Stage an entry deletion immediately before requesting.
    /// We do this for swipe-to-delete, where we must remove the entry
    /// from the list before requesting delete for the animation to work.
    case stageDeleteEntry(MemoAddress)
    /// Delete entry identified by slug.
    case deleteEntry(MemoAddress?)
    case failDeleteEntry(String)
    case succeedDeleteEntry(MemoAddress)
    
    /// Entry was saved
    case succeedSaveEntry(slug: MemoAddress, modified: Date)
    
    /// Move entry succeeded. Lifecycle action.
    case succeedMoveEntry(from: MemoAddress, to: MemoAddress)
    /// Merge entry succeeded. Lifecycle action.
    case succeedMergeEntry(parent: MemoAddress, child: MemoAddress)
    
    /// Audience was changed for address
    case succeedUpdateAudience(MoveReceipt)
    
    //  Search
    /// Hit submit ("go") while focused on search field
    case submitSearch(String)
    
    // Search suggestions
    /// Search suggestion was activated
    case activatedSuggestion(Suggestion)
    
    /// Set entire navigation stack
    case setDetails([MemoDetailDescription])
    
    /// Find a detail a given slashlink.
    /// If slashlink has a peer part, this will request
    /// a detail for 3p content.
    /// If slashlink does not have a peer part, this will
    /// request an editor detail.
    case findAndPushDetail(
        address: MemoAddress,
        link: SubSlashlinkLink
    )
    
    /// Find a detail for content that belongs to us.
    /// Detail could exist in either local or sphere content.
    case findAndPushMemoEditorDetail(
        slug: Slug,
        fallback: String
    )
    
    /// Push detail onto navigation stack
    case pushDetail(MemoDetailDescription)
    
    case pushRandomDetail(autofocus: Bool)
    case failPushRandomDetail(String)
    
    /// Set search query
    static func setSearch(_ query: String) -> NotebookAction {
        .search(.setQuery(query))
    }
    
    /// Synonym for `.pushDetail` that wraps editor detail in `.editor()`
    static func pushDetail(
        _ detail: MemoEditorDetailDescription
    ) -> Self {
        .pushDetail(.editor(detail))
    }
    
    /// Synonym for `.pushDetail` that wraps viewer detail in `.viewer()`
    static func pushDetail(
        _ detail: MemoViewerDetailDescription
    ) -> Self {
        .pushDetail(.viewer(detail))
    }
}

extension NotebookAction {
    /// Generate a detail request from a suggestion
    static func fromSuggestion(_ suggestion: Suggestion) -> Self {
        switch suggestion {
        case let .memo(address, fallback):
            return .pushDetail(
                MemoEditorDetailDescription(
                    address: address,
                    fallback: fallback
                )
            )
        case let .createLocalMemo(slug, fallback):
            return .pushDetail(
                MemoEditorDetailDescription(
                    address: slug?.toLocalMemoAddress(),
                    fallback: fallback,
                    defaultAudience: .local
                )
            )
        case let .createPublicMemo(slug, fallback):
            return .pushDetail(
                MemoEditorDetailDescription(
                    address: slug?.toPublicMemoAddress(),
                    fallback: fallback,
                    defaultAudience: .public
                )
            )
        case .random:
            return .pushRandomDetail(autofocus: false)
        }
    }
}

extension NotebookAction: CustomLogStringConvertible {
    var logDescription: String {
        switch self {
        case .search(let action):
            return "search(\(String.loggable(action)))"
        case .setRecent(let items):
            return "setRecent(\(items.count) items)"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Cursors and tagging functions

extension NotebookAction {
    static func tag(_ action: MemoEditorDetailNotification) -> Self {
        switch action {
        case .requestDelete(let address):
            return .deleteEntry(address)
        case let .requestDetail(detail):
            return .pushDetail(detail)
        case let .requestFindLinkDetail(link):
            return .findAndPushDetail(
                address: Slashlink.ourProfile.toPublicMemoAddress(),
                link: link
            )
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedSaveEntry(slug, modified):
            return .succeedSaveEntry(slug: slug, modified: modified)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        }
    }
    
    static func tag(_ action: MemoViewerDetailNotification) -> Self {
        switch action {
        case let .requestDetail(detail):
            return .pushDetail(detail)
        case let .requestFindLinkDetail(address, link):
            return .findAndPushDetail(
                address: address,
                link: link
            )
        }
    }
    
    static func tag(_ action: UserProfileDetailNotification) -> Self {
        switch action {
        case let .requestDetail(detail):
            return .pushDetail(detail)
        }
    }
}

extension NotebookAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        case .succeedMigrateDatabase:
            return .ready
        case .succeedSyncLocalFilesWithDatabase:
            return .ready
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

//  MARK: Model
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
    var details: [MemoDetailDescription] = []
    
    /// Count of entries
    var entryCount: Int? = nil
    
    ///  Recent entries (nil means "hasn't been loaded from DB")
    var recent: [EntryStub]? = nil
    
    //  Note deletion action sheet
    /// Delete confirmation action sheet
    var entryToDelete: MemoAddress? = nil
    /// Delete confirmation action sheet
    var isConfirmDeleteShowing = false
    
    //  MARK: Update
    //  !!!: Combine publishers can cause segfaults in Swift compiler
    //  Combine publishers have complex types and must be marked up carefully
    //  to avoid frequent segfaults in Swift compiler due to type inference
    //  (as of 2022-01-14).
    //
    //  We found the following mitigation/solution:
    //  - Mark publisher variables with explicit type annotations.
    //  - Beware Publishers.Merge and variants. Use publisher.merge instead.
    //    Publishers.Merge produces a more complex type signature, and this seems
    //    to be what was crashing the Swift compiler.
    //
    //  2022-01-14 Gordon Brander
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
        case let .confirmDelete(slug):
            guard let slug = slug else {
                logger.log(
                    "Delete confirmation flow passed nil slug. Doing nothing."
                )
                var model = state
                // Nil out entryToDelete, if any
                model.entryToDelete = nil
                return Update(state: model)
            }
            var model = state
            model.entryToDelete = slug
            model.isConfirmDeleteShowing = true
            return Update(state: model)
        case let .setConfirmDeleteShowing(isShowing):
            var model = state
            model.isConfirmDeleteShowing = isShowing
            // Reset entry to delete if we're dismissing the confirmation
            // dialog.
            if isShowing == false {
                model.entryToDelete = nil
            }
            return Update(state: model)
        case let .stageDeleteEntry(address):
            return stageDeleteEntry(
                state: state,
                environment: environment,
                address: address
            )
        case .deleteEntry(let address):
            return deleteEntry(
                state: state,
                environment: environment,
                address: address
            )
        case .failDeleteEntry(let error):
            logger.log("failDeleteEntry: \(error)")
            return Update(state: state)
        case .succeedDeleteEntry(let address):
            return succeedDeleteEntry(
                state: state,
                environment: environment,
                address: address
            )
        case .succeedSaveEntry:
            // Just refresh note after save, for now.
            // This reorders list by modified.
            return update(
                state: state,
                action: .listRecent,
                environment: environment
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
        case .submitSearch(let query):
            return submitSearch(
                state: state,
                environment: environment,
                query: query
            )
        case let .activatedSuggestion(suggestion):
            return update(
                state: state,
                action: NotebookAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .setDetails(let details):
            var model = state
            model.details = details
            return Update(state: model)
        case let .findAndPushDetail(address, link):
            // Stitch the base address on to the tapped link, making any
            // bare slashlinks relative to the sphere they belong to.
            //
            // This is needed in the viewer but address will always based
            // on our sphere in the editor case.
            let slashlink = Func.run {
                guard let basePetname = address.petname else {
                    return link.slashlink
                }
                
                return link.slashlink.relativeTo(petname: basePetname)
            }
            
            return findAndPushDetail(
                state: state,
                environment: environment,
                slashlink: slashlink,
                fallback: link.fallback
            )
        case let .findAndPushMemoEditorDetail(slug, fallback):
            return findAndPushMemoEditorDetail(
                state: state,
                environment: environment,
                slug: slug,
                fallback: fallback
            )
        case let .pushDetail(detail):
            var model = state
            model.details.append(detail)
            return Update(state: model)
        case .pushRandomDetail(let autofocus):
            return pushRandomDetail(
                state: state,
                environment: environment,
                autofocus: autofocus
            )
        case .failPushRandomDetail(let error):
            logger.log("Failed to get random note: \(error)")
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
        return Update(state: state)
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
        let fx: Fx<NotebookAction> = environment.data.countMemosPublisher()
            .map({ count in
                NotebookAction.setEntryCount(count)
            })
            .catch({ error in
                Just(NotebookAction.failEntryCount(error))
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
    
    /// Delete entry with `slug`
    static func stageDeleteEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        address: MemoAddress
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
        
        let fx: Fx<NotebookAction> = Just(NotebookAction.deleteEntry(address))
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
            .animation(.default)
    }
    
    /// Entry delete succeeded
    static func deleteEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        address: MemoAddress?
    ) -> Update<NotebookModel> {
        guard let address = address else {
            logger.log(
                "Delete requested for nil address. Doing nothing."
            )
            return Update(state: state)
        }
        let fx: Fx<NotebookAction> = environment.data
            .deleteMemoPublisher(address)
            .map({ _ in
                NotebookAction.succeedDeleteEntry(address)
            })
            .catch({ error in
                Just(
                    NotebookAction.failDeleteEntry(error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Entry delete succeeded
    static func succeedDeleteEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        address: MemoAddress
    ) -> Update<NotebookModel> {
        logger.log("Deleted entry: \(address)")
        var model = state
        model.details = state.details.filter({ detail in
            detail.address != address
        })
        return update(
            state: model,
            action: .refreshLists,
            environment: environment
        )
    }

    /// Move success lifecycle handler.
    /// Updates UI in response.
    static func succeedMoveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: MemoAddress,
        to: MemoAddress
    ) -> Update<NotebookModel> {
        var model = state

        /// Find all instances of this model in the stack and update them
        model.details = state.details.map({ (detail: MemoDetailDescription) in
            guard detail.address == from else {
                return detail
            }
            switch detail {
            case .editor(var description):
                description.address = to
                return .editor(description)
            case .viewer(var description):
                description.address = to
                return .viewer(description)
            case .profile(let description):
                return .profile(description)
            }
        })
        
        return update(
            state: model,
            action: .refreshLists,
            environment: environment
        )
    }

    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        parent: MemoAddress,
        child: MemoAddress
    ) -> Update<NotebookModel> {
        var model = state

        /// Find all instances of child and update them to become parent
        model.details = state.details.map({ (detail: MemoDetailDescription) in
            guard detail.address == child else {
                return detail
            }
            switch detail {
            case .editor(var description):
                description.address = parent
                return .editor(description)
            case .viewer(var description):
                description.address = parent
                return .viewer(description)
            case .profile(let description):
                return .profile(description)
            }
        })
        
        return update(
            state: model,
            action: .refreshLists,
            environment: environment
        )
    }

    /// Retitle success lifecycle handler.
    /// Updates UI in response.
    static func succeedUpdateAudience(
        state: NotebookModel,
        environment: AppEnvironment,
        receipt: MoveReceipt
    ) -> Update<NotebookModel> {
        var model = state

        /// Find all instances of this model in the stack and update them
        model.details = state.details.map({ (detail: MemoDetailDescription) in
            guard let address = detail.address else {
                return detail
            }
            guard address.slug == receipt.to.slug else {
                return detail
            }
            switch detail {
            case .editor(var description):
                description.address = receipt.to
                return .editor(description)
            case .viewer(var description):
                description.address = receipt.to
                return .viewer(description)
            case .profile(let description):
                return .profile(description)
            }
        })
        
        return update(
            state: model,
            action: .refreshLists,
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
            let address = Slug(formatting: query)?.toLocalMemoAddress()
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
    
    /// Find and push a specific detail for slug
    static func findAndPushDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        slashlink: Slashlink,
        fallback: String
    ) -> Update<NotebookModel> {
        // If slashlink pointing to our sphere, dispatch findAndPushEditDetail
        // to find in local or sphere content and then push editor detail.
        guard slashlink.petname != nil else {
            return update(
                state: state,
                action: .findAndPushMemoEditorDetail(
                    slug: slashlink.toSlug(),
                    fallback: fallback
                ),
                environment: environment
            )
        }
        
        if AppDefaults.standard.isNoosphereEnabled {
            // Intercept profile visits and use the correct view
            guard !slashlink.slug.isProfile else {
                return update(
                    state: state,
                    action: .pushDetail(
                        .profile(
                            UserProfileDetailDescription(
                                address: slashlink.toPublicMemoAddress()
                            )
                        )
                    ),
                    environment: environment
                )
            }
            
            // If Noosphere is enabled, and slashlink pointing to other sphere,
            // dispatch action for viewer.
            return update(
                state: state,
                action: .pushDetail(
                    .viewer(
                        MemoViewerDetailDescription(
                            address: slashlink.toPublicMemoAddress()
                        )
                    )
                ),
                environment: environment
            )
        } else {
            // Otherwise debug log and do nothing.
            logger.debug(
                "Slashlink to other sphere requested, but viewing other sphere content is disabled. Doing nothing."
            )
            return Update(state: state)
        }
    }
    
    /// Find and push a specific detail for slug
    static func findAndPushMemoEditorDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug,
        fallback: String
    ) -> Update<NotebookModel> {
        let fallbackAddress = slug.toLocalMemoAddress()
        let fx: Fx<NotebookAction> = environment.data
            .findAddressInOursPublisher(slug: slug)
            .map({ address in
                NotebookAction.pushDetail(
                    MemoEditorDetailDescription(
                        address: address ?? fallbackAddress,
                        fallback: fallback
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Request detail for a random entry
    static func pushRandomDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        autofocus: Bool
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data
            .readRandomEntryLinkPublisher()
            .map({ link in
                NotebookAction.pushDetail(
                    MemoEditorDetailDescription(
                        address: link.address,
                        fallback: link.title
                    )
                )
            })
            .catch({ error in
                Just(
                    NotebookAction.failPushRandomDetail(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
}
