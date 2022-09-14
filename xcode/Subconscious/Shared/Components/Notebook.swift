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

//  MARK: Action
/// Actions for modifying state
/// For action naming convention, see
/// https://github.com/gordonbrander/subconscious/wiki/action-naming-convention
enum NotebookAction {
    /// Tagged action for search HUD
    case search(SearchAction)
    /// Tagged action for detail
    case detail(DetailAction)
    case showDetail(Bool)

    /// KeyboardService state change.
    /// Action passed down from parent component.
    case changeKeyboardState(KeyboardState)

    /// On appear. We rely on parent to notify us of this event.
    case appear

    /// Refresh the state of all lists by reloading from database.
    /// This also sets searches to their zero-query state.
    case refreshAll

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
    case deleteEntry(Slug)
    case deleteEntrySuccess(Slug)
    case deleteEntryFailure(String)

    //  Search
    /// Hit submit ("go") while focused on search field
    case submitSearch(String)

    // Search suggestions
    /// Search suggestion was activated
    case activatedSuggestion(Suggestion)

    /// Set search query
    static func setSearch(_ query: String) -> NotebookAction {
        .search(.setQuery(query))
    }

    /// Show/hide the search HUD
    static func setSearchPresented(_ isPresented: Bool) -> NotebookAction {
        .search(.setPresented(isPresented))
    }

    /// Forward requestDetail action to detail
    static func requestDetail(
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    ) -> Self {
        .detail(
            .requestDetail(
                slug: slug,
                fallback: fallback,
                autofocus: autofocus
            )
        )
    }

    /// request detail for slug, using template file as a fallback
    static func requestTemplateDetail(
        slug: Slug,
        template: Slug,
        autofocus: Bool
    ) -> Self {
        .detail(
            .requestTemplateDetail(
                slug: slug,
                template: template,
                autofocus: autofocus
            )
        )
    }

    static func requestRandomDetail(autofocus: Bool) -> Self {
        .detail(
            .requestRandomDetail(autofocus: autofocus)
        )
    }

    /// Send autosave to detail
    static let autosave = Self.detail(.autosave)

    static func updateDetail(detail: EntryDetail, autofocus: Bool) -> Self {
        Self.detail(.updateDetail(detail: detail, autofocus: autofocus))
    }

    static func setLinkSearch(_ query: String) -> Self {
        .detail(.setLinkSearch(query))
    }
}

extension NotebookAction: CustomLogStringConvertible {
    var logDescription: String {
        switch self {
        case .detail(let action):
            return "detail(\(String.loggable(action)))"
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

/// Cursor for detail view
//  This is a non-standard cursor because Detail is not yet factored out
//  into a stand-alone component. Instead, we just have a handful of actions
//  we map to/from and a model we construct on the fly. We should factor
//  out detail into a proper component.
struct NotebookDetailCursor: CursorProtocol {
    static func get(state: NotebookModel) -> DetailModel {
        state.detail
    }

    static func set(state: NotebookModel, inner: DetailModel) -> NotebookModel {
        var model = state
        model.detail = inner
        return model
    }

    static func tag(_ action: DetailAction) -> NotebookAction {
        switch action {
        case .refreshAll:
            return .refreshAll
        case .showDetail(let isShowing):
            return .showDetail(isShowing)
        case .requestDeleteEntry(let slug):
            return .confirmDelete(slug)
        default:
            return .detail(action)
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
        default:
            return .search(action)
        }
    }
}

//  MARK: Model
/// Model containing state for the notebook tab.
struct NotebookModel: ModelProtocol {
    //  Current state of keyboard
    /// Keyboard preparing to show
    var keyboardWillShow = false
    /// Keyboard height at end of animation
    var keyboardEventualHeight: CGFloat = 0

    var isFabShowing = true

    /// Search HUD
    var search = SearchModel()

    /// Is the detail view (edit and details for an entry) showing?
    var isDetailShowing = false

    /// Entry detail
    var detail = DetailModel()

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
        case .detail(let action):
            return NotebookDetailCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case let .changeKeyboardState(keyboard):
            return changeKeyboardState(state: state, keyboard: keyboard)
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case .refreshAll:
            return refreshAll(state: state, environment: environment)
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
            return warn(
                state: state,
                environment: environment,
                error: error
            )
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
        case let .deleteEntry(slug):
            return deleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case let .deleteEntrySuccess(slug):
            return deleteEntrySuccess(
                state: state,
                environment: environment,
                slug: slug
            )
        case let .deleteEntryFailure(error):
            environment.logger.log("Failed to delete entry: \(error)")
            return Update(state: state)
        case let .showDetail(isShowing):
            return showDetail(
                state: state,
                environment: environment,
                isShowing: isShowing
            )
        case .submitSearch(let query):
            return submitSearch(
                state: state,
                environment: environment,
                query: query
            )
        case let .activatedSuggestion(suggestion):
            return NotebookDetailCursor.update(
                state: state,
                action: DetailAction.fromSuggestion(suggestion),
                environment: environment
            )
        }
    }

    /// Log error at log level
    static func log(
        state: NotebookModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<NotebookModel> {
        environment.logger.log("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Log error at warning level
    static func warn(
        state: NotebookModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<NotebookModel> {
        environment.logger.warning("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Change state of keyboard
    /// Actions come from `KeyboardService`
    static func changeKeyboardState(
        state: NotebookModel,
        keyboard: KeyboardState
    ) -> Update<NotebookModel> {
        switch keyboard {
        case
            .willShow(let size, _),
            .didShow(let size),
            .didChangeFrame(let size):
            var model = state
            model.keyboardWillShow = true
            model.keyboardEventualHeight = size.height
            return Update(state: model)
        case .willHide:
            return Update(state: state)
        case .didHide:
            var model = state
            model.keyboardWillShow = false
            model.keyboardEventualHeight = 0
            return Update(state: model)
        }
    }

    /// Appear (when view first renders)
    static func appear(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = Just(NotebookAction.countEntries)
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Toggle detail view showing or hiding
    static func showDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        isShowing: Bool
    ) -> Update<NotebookModel> {
        var model = state
        model.isDetailShowing = isShowing
        return Update(state: model)
    }

    /// Refresh all lists in the notebook tab from database.
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshAll(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        let detailRefreshFx: Fx<NotebookAction> = Just(
            .detail(DetailAction.refreshAll)
        )
        .eraseToAnyPublisher()

        let countFx: Fx<NotebookAction> = Just(
            NotebookAction.countEntries
        )
        .eraseToAnyPublisher()

        let listFx: Fx<NotebookAction> = Just(
            NotebookAction.listRecent
        )
        .eraseToAnyPublisher()

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.search(.refreshSuggestions)
        )
        .merge(with: detailRefreshFx, countFx, listFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Read entry count from db
    static func countEntries(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = environment.database.countEntries()
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
        let fx: Fx<NotebookAction> = environment.database
            .listRecentEntries()
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
    static func deleteEntry(
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

        // Hide detail view.
        // Delete may have been invoked from detail view
        // in which case, we don't want it showing.
        // If it was invoked from list view, then setting this to false
        // is harmless.
        model.isDetailShowing = false

        let fx: Fx<NotebookAction> = environment.database
            .deleteEntryAsync(slug: slug)
            .map({ _ in
                NotebookAction.deleteEntrySuccess(slug)
            })
            .catch({ error in
                Just(
                    NotebookAction.deleteEntryFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
            .animation(.default)
    }

    /// Handle completion of entry delete
    static func deleteEntrySuccess(
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<NotebookModel> {
        environment.logger.log("Deleted entry: \(slug)")
        //  Refresh lists in search fields after delete.
        //  This ensures they don't show the deleted entry.
        let refreshFx: Fx<NotebookAction> = Just(NotebookAction.refreshAll)
            .eraseToAnyPublisher()

        guard state.detail.slug == slug else {
            return Update(state: state, fx: refreshFx)
        }

        // If we just deleted the entry currently being edited,
        // reset the editor to initial state (nothing is being edited).
        let fx: Fx<NotebookAction> = Just(
            NotebookAction.detail(.resetDetail)
        )
        .merge(with: refreshFx)
        .eraseToAnyPublisher()

        // Hide detail
        var model = state
        model.isDetailShowing = false

        return Update(state: model, fx: fx)
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
        let submitFx: Fx<NotebookAction> = Just(
            NotebookAction.search(.submitQuery(query))
        )
        .eraseToAnyPublisher()

        // Derive slug. If we can't (e.g. invalid query such as empty string),
        // just hide the search HUD and do nothing.
        guard let slug = Slug(formatting: query) else {
            environment.logger.log(
                "Query could not be converted to slug: \(query)"
            )
            return Update(state: state, fx: submitFx)
        }

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.requestDetail(
                slug: slug,
                fallback: query,
                autofocus: true
            )
        )
        // Request detail AFTER animaiton completes
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .merge(with: submitFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }
}

//  MARK: View
/// The file view for notes
struct NotebookView: View {
    var store: ViewStore<NotebookModel>

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
                store: ViewStore(
                    store: store,
                    cursor: NotebookSearchCursor.self
                )
            )
            .zIndex(3)
        }
    }
}
