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
    @ObservedObject var parent: Store<AppModel>
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
            NotebookNavigationView(store: store)
                .zIndex(1)
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
            SearchView(
                state: store.state.search,
                send: Address.forward(
                    send: store.send,
                    tag: NotebookSearchCursor.tag
                )
            )
            .zIndex(3)
        }
        .onAppear {
            store.send(.appear)
        }
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
    case confirmDelete(Slug?)
    case setConfirmDeleteShowing(Bool)
    /// Stage an entry deletion immediately before requesting.
    /// We do this for swipe-to-delete, where we must remove the entry
    /// from the list before requesting delete for the animation to work.
    case stageDeleteEntry(Slug)
    /// Delete entry identified by slug.
    case deleteEntry(Slug?)
    case failDeleteEntry(String)
    case succeedDeleteEntry(Slug)

    // Rename entry
    /// Issue a rename action for an entry.
    case renameEntry(RenameSuggestion)
    /// Move entry succeeded. Lifecycle action.
    case succeedMoveEntry(from: EntryLink, to: EntryLink)
    /// Move entry failed. Lifecycle action.
    case failMoveEntry(String)
    /// Merge entry succeeded. Lifecycle action.
    case succeedMergeEntry(parent: EntryLink, child: EntryLink)
    /// Merge entry failed. Lifecycle action.
    case failMergeEntry(String)
    /// Retitle entry succeeded. Lifecycle action.
    case succeedRetitleEntry(from: EntryLink, to: EntryLink)
    /// Retitle entry failed. Lifecycle action.
    case failRetitleEntry(String)

    //  Search
    /// Hit submit ("go") while focused on search field
    case submitSearch(String)
    
    // Search suggestions
    /// Search suggestion was activated
    case activatedSuggestion(Suggestion)
    
    /// Set entire navigation stack
    case setDetails([DetailOuterModel])
    /// Push detail onto navigation stack
    case pushDetail(
        slug: Slug,
        title: String,
        fallback: String,
        autofocus: Bool
    )
    
    case pushRandomDetail(autofocus: Bool)
    case failPushRandomDetail(String)
    
    /// Set search query
    static func setSearch(_ query: String) -> NotebookAction {
        .search(.setQuery(query))
    }
    
    /// Show/hide the search HUD
    static func setSearchPresented(_ isPresented: Bool) -> NotebookAction {
        .search(.setPresented(isPresented))
    }
    
    private static func generateScratchFallback(date: Date) -> String {
        let formatter = DateFormatter.yyyymmdd()
        let yyyymmdd = formatter.string(from: date)
        return "[[\(yyyymmdd)]]"
    }
}

extension NotebookAction {
    /// Generate a detail request from a suggestion
    static func fromSuggestion(_ suggestion: Suggestion) -> Self {
        switch suggestion {
        case .entry(let entryLink):
            return .pushDetail(
                slug: entryLink.slug,
                title: entryLink.linkableTitle,
                fallback: entryLink.title,
                autofocus: false
            )
        case .search(let entryLink):
            return .pushDetail(
                slug: entryLink.slug,
                title: entryLink.linkableTitle,
                fallback: entryLink.title,
                autofocus: false
            )
        case .scratch(let entryLink):
            return .pushDetail(
                slug: entryLink.slug,
                title: entryLink.linkableTitle,
                fallback: generateScratchFallback(date: Date.now),
                autofocus: false
            )
        case .random:
            return .pushRandomDetail(autofocus: false)
        }
    }
}

extension NotebookAction {
    static func tag(_ action: DetailOuterAction) -> Self {
        switch action {
        case .requestDelete(let slug):
            return .deleteEntry(slug)
        case let .requestDetail(slug, title, fallback):
            return .pushDetail(
                slug: slug,
                title: title,
                fallback: fallback,
                autofocus: false
            )
        case .renameEntry(let suggestion):
            return .renameEntry(suggestion)
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

//  MARK: Cursors

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
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
    /// Contains notebook detail panels
    var details: [DetailOuterModel] = []
    
    /// Count of entries
    var entryCount: Int? = nil
    
    ///  Recent entries (nil means "hasn't been loaded from DB")
    var recent: [EntryStub]? = nil
    
    //  Note deletion action sheet
    /// Delete confirmation action sheet
    var entryToDelete: Slug? = nil
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
            environment.logger.warning(
                "Failed to list recent entries: \(error)"
            )
            return Update(state: state)
        case let .confirmDelete(slug):
            guard let slug = slug else {
                environment.logger.log(
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
        case let .stageDeleteEntry(slug):
            return stageDeleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case .deleteEntry(let slug):
            return deleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case .failDeleteEntry(let error):
            logger.log("failDeleteEntry: \(error)")
            return Update(state: state)
        case .succeedDeleteEntry(let slug):
            return succeedDeleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case .renameEntry(let suggestion):
            return renameEntry(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case let .succeedMoveEntry(from, to):
            return succeedMoveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .failMoveEntry(let error):
            return failMoveEntry(
                state: state,
                environment: environment,
                error: error
            )
        case let .succeedMergeEntry(parent, child):
            return succeedMergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case .failMergeEntry(let error):
            return failMergeEntry(
                state: state,
                environment: environment,
                error: error
            )
        case let .succeedRetitleEntry(from, to):
            return succeedRetitleEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .failRetitleEntry(let error):
            return failRetitleEntry(
                state: state,
                environment: environment,
                error: error
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
        case let .pushDetail(slug, title, fallback, _):
            var model = state
            model.details.append(
                DetailOuterModel(
                    slug: slug,
                    title: title,
                    fallback: fallback
                )
            )
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
        /// Subscribe to database state publisher to know when ready to query.
        let databaseStateFx = environment.data.database.$state.map({ state in
            NotebookAction.databaseStateChange(state)
        })
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: databaseStateFx)
    }
    
    /// View is ready
    static func ready(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        return update(
            state: state,
            actions: [
                .countEntries,
                .refreshLists
            ],
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
        let fx: Fx<NotebookAction> = environment.data.countEntries()
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
        let fx: Fx<NotebookAction> = environment.data.listRecentEntries()
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
        slug: Slug
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
            let index = recent.firstIndex(
                where: { stub in stub.id == slug }
            ) {
            recent.remove(at: index)
            model.recent = recent
        }
        
        let fx: Fx<NotebookAction> = Just(
            NotebookAction.deleteEntry(slug)
        )
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
            .animation(.default)
    }
    
    /// Entry delete succeeded
    static func deleteEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug?
    ) -> Update<NotebookModel> {
        guard let slug = slug else {
            logger.log(
                "Delete requested for nil slug. Doing nothing."
            )
            return Update(state: state)
        }
        let fx: Fx<NotebookAction> = environment.data
            .deleteEntryAsync(slug: slug)
            .map({ _ in
                NotebookAction.succeedDeleteEntry(slug)
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
        slug: Slug
    ) -> Update<NotebookModel> {
        logger.log("Deleted entry: \(slug)")
        var model = state
        model.details = state.details.filter({ detail in
            detail.slug != slug
        })
        return update(
            state: model,
            action: .refreshLists,
            environment: environment
        )
    }

    /// Rename an entry (change its slug).
    /// If `next` does not already exist, this will change the slug
    /// and move the file.
    /// If next exists, this will merge documents.
    static func renameEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        suggestion: RenameSuggestion
    ) -> Update<NotebookModel> {
        switch suggestion {
        case .move(let from, let to):
            return moveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .merge(let parent, let child):
            return mergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case .retitle(let from, let to):
            return retitleEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        }
    }

    /// Move entry
    static func moveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data
            .moveEntryAsync(from: from, to: to)
            .map({ _ in
                NotebookAction.succeedMoveEntry(from: from, to: to)
            })
            .catch({ error in
                Just(
                    NotebookAction.failMoveEntry(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(
            state: state,
            fx: fx
        )
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Move success lifecycle handler.
    /// Updates UI in response.
    static func succeedMoveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<NotebookModel> {
        var model = state

        /// Find all instances of this model in the stack and update them
        model.details = state.details.map({ (detail: DetailOuterModel) in
            guard detail.slug == from.slug else {
                return detail
            }
            var model = detail
            model.slug = to.slug
            model.title = to.linkableTitle
            model.fallback = to.title
            return model
        })
        
        return update(
            state: model,
            action: .refreshLists,
            environment: environment
        )
    }

    /// Move failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMoveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel> {
        environment.logger.warning(
            "Failed to move entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Merge entry
    static func mergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        parent: EntryLink,
        child: EntryLink
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data
            .mergeEntryAsync(parent: parent, child: child)
            .map({ _ in
                NotebookAction.succeedMergeEntry(parent: parent, child: child)
            })
            .catch({ error in
                Just(
                    NotebookAction.failMergeEntry(error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        parent: EntryLink,
        child: EntryLink
    ) -> Update<NotebookModel> {
        logger.warning("Not implemented yet")
        return Update(state: state)
    }

    /// Merge failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel> {
        environment.logger.warning(
            "Failed to merge entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Retitle entry
    static func retitleEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data
            .retitleEntryAsync(from: from, to: to)
            .map({ _ in
                NotebookAction.succeedRetitleEntry(from: from, to: to)
            })
            .catch({ error in
                Just(
                    NotebookAction.failRetitleEntry(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Retitle success lifecycle handler.
    /// Updates UI in response.
    static func succeedRetitleEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<NotebookModel> {
        logger.warning("Not implemented")
        return Update(state: state)
    }

    /// Retitle failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failRetitleEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel> {
        logger.warning(
            "Failed to retitle entry with error: \(error)"
        )
        return Update(state: state)
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
        guard let link = EntryLink(title: query) else {
            environment.logger.log(
                "Query could not be converted to link: \(query)"
            )
            return update
        }
        
        // Request detail AFTER animaiton completes
        let fx: Fx<NotebookAction> = Just(
            NotebookAction.pushDetail(
                slug: link.slug,
                title: link.linkableTitle,
                fallback: link.title,
                autofocus: false
            )
        )
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
        
        return update.mergeFx(fx)
    }
    
    /// Request detail for a random entry
    static func pushRandomDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        autofocus: Bool
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.data.readRandomEntryLink()
            .map({ link in
                NotebookAction.pushDetail(
                    slug: link.slug,
                    title: link.linkableTitle,
                    fallback: link.title,
                    autofocus: autofocus
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
