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

    /// On appear. We rely on parent to notify us of this event.
    case appear

    /// Refresh the state of all lists and child components by reloading
    /// from database. This also sets searches to their zero-query state.
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

    // Entry CRUD actions
    case succeedSaveEntry(SubtextFile)
    /// Move entry succeeded. Lifecycle action from Detail.
    case succeedMoveEntry(from: EntryLink, to: EntryLink)
    /// Merge entry succeeded. Lifecycle action from Detail.
    case succeedMergeEntry(parent: EntryLink, child: EntryLink)
    /// Retitle entry succeeded. Lifecycle action from Detail.
    case succeedRetitleEntry(from: EntryLink, to: EntryLink)

    // Delete entries
    case confirmDelete(Slug?)
    case setConfirmDeleteShowing(Bool)
    /// Stage an entry deletion immediately before requesting.
    /// We do this for swipe-to-delete, where we must remove the entry
    /// from the list before requesting delete for the animation to work.
    case stageDeleteEntry(Slug)
    /// Send entry delete request up to parent.
    case requestDeleteEntry(Slug?)
    /// Handle entry having been deleted.
    /// This action is typically sent down from a parent component to notify
    /// of a deletion having happened here or somewhere else.
    case entryDeleted(Slug)

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
    static func loadAndPresentDetail(
        link: EntryLink?,
        fallback: String,
        autofocus: Bool
    ) -> Self {
        .detail(
            .loadAndPresentDetail(
                link: link,
                fallback: fallback,
                autofocus: autofocus
            )
        )
    }

    /// request detail for slug, using template file as a fallback
    static func loadAndPresentTemplateDetail(
        link: EntryLink,
        template: Slug,
        autofocus: Bool
    ) -> Self {
        .detail(
            .loadAndPresentTemplateDetail(
                link: link,
                template: template,
                autofocus: autofocus
            )
        )
    }

    static func loadAndPresentRandomDetail(autofocus: Bool) -> Self {
        .detail(
            .loadAndPresentRandomDetail(autofocus: autofocus)
        )
    }

    /// Send autosave to detail
    static let autosave = Self.detail(.autosave)

    static func presentDetail(_ isPresented: Bool) -> Self {
        .detail(.presentDetail(isPresented))
    }

    static func setLinkSearch(_ query: String) -> Self {
        .detail(.setLinkSearch(query))
    }

    /// Notification passed down from parent component,
    /// driven by KeyboardService.
    static func setKeyboardHeight(_ height: CGFloat) -> Self {
        .search(.setKeyboardHeight(height))
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
        case .succeedSaveEntry(let entry):
            return "succeedSaveEntry(\(entry.slug))"
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
        case let .succeedSave(entry):
            return .succeedSaveEntry(entry)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedRetitleEntry(from, to):
            return .succeedRetitleEntry(from: from, to: to)
        case .requestDeleteEntry(let slug):
            return .requestDeleteEntry(slug)
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
    var isFabShowing = true

    /// Search HUD
    var search = SearchModel(
        placeholder: "Search or create..."
    )

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
        case let .stageDeleteEntry(slug):
            return stageDeleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case .requestDeleteEntry(_):
            environment.logger.debug(
                "requestDeleteEntry should be handled by parent component"
            )
            return Update(state: state)
        case let .entryDeleted(slug):
            return NotebookModel.update(
                state: state,
                actions: [
                    .detail(.entryDeleted(slug)),
                    .search(.entryDeleted(slug)),
                    .countEntries,
                    .listRecent
                ],
                environment: environment
            )
        case let .succeedSaveEntry(entry):
            return update(
                state: state,
                actions: [
                    .detail(.succeedSave(entry)),
                    .search(.refreshSuggestions),
                    .listRecent,
                    .countEntries
                ],
                environment: environment
            )
        case let .succeedMoveEntry(from, to):
            return update(
                state: state,
                actions: [
                    .detail(.succeedMoveEntry(from: from, to: to)),
                    .search(.refreshSuggestions),
                    .listRecent,
                    .countEntries
                ],
                environment: environment
            )
        case let .succeedMergeEntry(parent, child):
            return update(
                state: state,
                actions: [
                    .detail(.succeedMergeEntry(parent: parent, child: child)),
                    .search(.refreshSuggestions),
                    .listRecent,
                    .countEntries
                ],
                environment: environment
            )
        case let .succeedRetitleEntry(from, to):
            return update(
                state: state,
                actions: [
                    .detail(.succeedRetitleEntry(from: from, to: to)),
                    .search(.refreshSuggestions),
                    .listRecent
                ],
                environment: environment
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

    /// Appear (when view first renders)
    static func appear(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        let fx: Fx<NotebookAction> = Just(NotebookAction.countEntries)
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Refresh all lists in the notebook tab from database.
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshAll(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel> {
        return NotebookModel.update(
            state: state,
            actions: [
                .detail(.refreshLists),
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
            NotebookAction.requestDeleteEntry(slug)
        )
        .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
            .animation(.default)
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

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.loadAndPresentDetail(
                link: link,
                fallback: query,
                autofocus: true
            )
        )
        // Request detail AFTER animaiton completes
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()

        return update.mergeFx(fx)
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
