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
    case focus(AppFocusAction)
    // Tagged action for detail
    case detail(DetailAction)
    case showDetail(Bool)

    case noop

    //  URL handlers
    case openURL(URL)
    case openEditorURL(URL)

    /// Request a model-driven focus change
    case requestFocus(AppFocus?)
    /// Focus change request scheduled
    case focusRequestScheduled
    /// Focus change from the UI. UI-driven focus always wins.
    case focusChange(AppFocus?)

    /// KeyboardService state change.
    /// Action passed down from parent component.
    case changeKeyboardState(KeyboardState)

    /// On appear. We rely on parent to notify us of this event.
    case appear

    /// Refresh the state of all lists by reloading from database.
    /// This also sets searches to their zero-query state.
    case refreshAll

    //  Search history
    /// Write a search history event to the database
    case createSearchHistoryItem(String)
    case createSearchHistoryItemSuccess(String)
    case createSearchHistoryItemFailure(String)

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
    /// Set search text (updated live as you type)
    case setSearch(String)
    case showSearch
    case hideSearch
    /// Hit submit ("go") while focused on search field
    case submitSearch(String)

    // Search suggestions
    /// Submit search suggestion
    case selectSuggestion(Suggestion)
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)

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

extension NotebookAction {
    /// Generates a short (approximately 1 line) loggable string for action.
    func toLogString() -> String {
        switch self {
        case .setRecent(let items):
            return "setRecent(...) (\(items.count) items)"
        case .setSuggestions(let items):
            return "setSuggestions(...) (\(items.count) items)"
        default:
            return String(describing: self)
        }
    }
}


//  MARK: Model
/// Model containing state for the notebook tab.
struct NotebookModel: Hashable, Equatable {
    /// State reflecting global app focus state.
    var focus: AppFocusModel

    //  Current state of keyboard
    /// Keyboard preparing to show
    var keyboardWillShow = false
    /// Keyboard height at end of animation
    var keyboardEventualHeight: CGFloat = 0

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

    /// Live search bar text
    var searchText = ""
    var isSearchShowing = false

    /// Main search suggestions
    var suggestions: [Suggestion] = []
}

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
extension NotebookModel {
    /// Main update function
    static func update(
        state: NotebookModel,
        action: NotebookAction,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
        switch action {
        case .focus(let action):
            return NotebookFocusCursor.update(
                with: AppFocusModel.update,
                state: state,
                action: action,
                environment: ()
            )
        case .detail(let action):
            return NotebookDetailCursor.update(
                with: DetailModel.update,
                state: state,
                action: action,
                environment: environment
            )
        case .noop:
            return Update(state: state)
        case .requestFocus(let focus):
            return requestFocus(
                state: state,
                environment: environment,
                focus: focus
            )
        case .focusRequestScheduled:
            return focusRequestScheduled(
                state: state,
                environment: environment
            )
        case .focusChange(let focus):
            return focusChange(
                state: state,
                environment: environment,
                focus: focus
            )
        case let .openURL(url):
            UIApplication.shared.open(url)
            return Update(state: state)
        case let .openEditorURL(url):
            return openEditorURL(state: state, url: url)
        case let .changeKeyboardState(keyboard):
            return changeKeyboardState(state: state, keyboard: keyboard)
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case .refreshAll:
            return refreshAll(state: state, environment: environment)
        case let .createSearchHistoryItem(query):
            return createSearchHistoryItem(
                state: state,
                environment: environment,
                query: query
            )
        case let .createSearchHistoryItemSuccess(query):
            return createSearchHistoryItemSuccess(
                state: state,
                environment: environment,
                query: query
            )
        case let .createSearchHistoryItemFailure(error):
            return createSearchHistoryItemFailure(
                state: state,
                environment: environment,
                error: error
            )
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
        case let .setSearch(text):
            return setSearch(
                state: state,
                environment: environment,
                text: text
            )
        case .showSearch:
            var model = state
            model.isSearchShowing = true
            model.searchText = ""
            let fx: Fx<NotebookAction> = Just(
                NotebookAction.requestFocus(.search)
            )
            .eraseToAnyPublisher()
            return Update(state: model, fx: fx)
                .animation(.easeOutCubic(duration: Duration.keyboard))
        case .hideSearch:
            return hideSearch(
                state: state,
                environment: environment
            )
        case .submitSearch(let query):
            return submitSearch(
                state: state,
                environment: environment,
                query: query
            )
        case let .selectSuggestion(suggestion):
            return selectSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case let .setSuggestions(suggestions):
            var model = state
            model.suggestions = suggestions
            return Update(state: model)
        case let .suggestionsFailure(message):
            environment.logger.debug(
                "Suggest failed: \(message)"
            )
            return Update(state: state)
        }
    }

    /// Log error at log level
    static func log(
        state: NotebookModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.log("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Log error at warning level
    static func warn(
        state: NotebookModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.warning("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Handle requestFocus and send to both child components
    /// that need focus information.
    static func requestFocus(
        state: NotebookModel,
        environment: AppEnvironment,
        focus: AppFocus?
    ) -> Update<NotebookModel, NotebookAction> {
        let focusFx: Fx<NotebookAction> = Just(
            NotebookAction.focus(.requestFocus(focus))
        )
        .eraseToAnyPublisher()

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.detail(.requestFocus(focus))
        )
        .merge(with: focusFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Handle focusRequestScheduled and send to both child components
    /// that need focus information.
    static func focusRequestScheduled(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
        let focusFx: Fx<NotebookAction> = Just(
            NotebookAction.focus(.focusRequestScheduled)
        )
        .eraseToAnyPublisher()

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.detail(.focusRequestScheduled)
        )
        .merge(with: focusFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Handle focusChange and send to both child components
    /// that need focus information.
    static func focusChange(
        state: NotebookModel,
        environment: AppEnvironment,
        focus: AppFocus?
    ) -> Update<NotebookModel, NotebookAction> {
        let focusFx: Fx<NotebookAction> = Just(
            NotebookAction.focus(.focusChange(focus))
        )
        .eraseToAnyPublisher()

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.detail(.focusChange(focus))
        )
        .merge(with: focusFx)
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Change state of keyboard
    /// Actions come from `KeyboardService`
    static func changeKeyboardState(
        state: NotebookModel,
        keyboard: KeyboardState
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = Just(NotebookAction.countEntries)
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Toggle detail view showing or hiding
    static func showDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        isShowing: Bool
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.isDetailShowing = isShowing
        return Update(state: model)
    }

    static func openEditorURL(
        state: NotebookModel,
        url: URL
    ) -> Update<NotebookModel, NotebookAction> {
        // Follow ordinary links when not in edit mode
        guard SubURL.isSubEntryURL(url) else {
            UIApplication.shared.open(url)
            return Update(state: state)
        }

        let link = EntryLink.decodefromSubEntryURL(url)
        let fx: Fx<NotebookAction> = Just(
            NotebookAction.requestDetail(
                slug: link?.slug,
                fallback: link?.title ?? "",
                autofocus: false
            )
        )
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Refresh all lists in the app from database
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshAll(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
        let detailRefreshFx: Fx<NotebookAction> = Just(
            .detail(DetailAction.refreshAll)
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: detailRefreshFx)
            .pipe({ state in
                listRecent(
                    state: state,
                    environment: environment
                )
            })
            .pipe({ state in
                setSearch(
                    state: state,
                    environment: environment,
                    text: state.searchText
                )
            })
            .pipe({ state in
                countEntries(
                    state: state,
                    environment: environment
                )
            })
    }

    /// Insert search history event into database
    static func createSearchHistoryItem(
        state: NotebookModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = environment.database
            .createSearchHistoryItem(query: query)
            .map({ result in
                NotebookAction.noop
            })
            .catch({ error in
                Just(
                    NotebookAction.createSearchHistoryItemFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle success case for search history item creation
    static func createSearchHistoryItemSuccess(
        state: NotebookModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.log(
            "Created search history entry: \(query)"
        )
        return Update(state: state)
    }

    /// Handle failure case for search history item creation
    static func createSearchHistoryItemFailure(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.warning(
            "Failed to create search history entry: \(error)"
        )
        return Update(state: state)
    }

    /// Read entry count from db
    static func countEntries(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.entryCount = count
        return Update(state: model)
    }

    static func listRecent(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
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

    /// Set search text for main search input
    static func setSearch(
        state: NotebookModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.searchText = text
        let fx: Fx<NotebookAction> = environment.database
            .searchSuggestions(
                query: text,
                isJournalSuggestionEnabled:
                    Config.default.journalSuggestionEnabled,
                isScratchSuggestionEnabled:
                    Config.default.scratchSuggestionEnabled,
                isRandomSuggestionEnabled:
                    Config.default.randomSuggestionEnabled
            )
            .map({ suggestions in
                NotebookAction.setSuggestions(suggestions)
            })
            .catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }

    /// Set search HUD to hidden state
    static func hideSearch(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.isSearchShowing = false
        model.searchText = ""

        let fx: Fx<NotebookAction> = Just(
            NotebookAction.requestFocus(nil)
        )
        .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Submit a search query (typically by hitting "go" on keyboard)
    static func submitSearch(
        state: NotebookModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<NotebookModel, NotebookAction> {
        // Duration of keyboard animation
        let duration = Duration.keyboard
        let delay = duration + 0.03

        let update = hideSearch(
            state: state,
            environment: environment
        )
        .animation(.easeOutCubic(duration: duration))

        // Derive slug. If we can't (e.g. invalid query such as empty string),
        // just hide the search HUD and do nothing.
        guard let slug = Slug(formatting: query) else {
            environment.logger.log(
                "Query could not be converted to slug: \(query)"
            )
            return update
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
        .eraseToAnyPublisher()

        return update.mergeFx(fx)
    }

    /// Handle user select search suggestion
    static func selectSuggestion(
        state: NotebookModel,
        environment: AppEnvironment,
        suggestion: Suggestion
    ) -> Update<NotebookModel, NotebookAction> {
        // Duration of keyboard animation
        let duration = Duration.keyboard
        let delay = duration + 0.03

        let update = hideSearch(
            state: state,
            environment: environment
        )
        .animation(.easeOutCubic(duration: duration))

        switch suggestion {
        case .entry(let entryLink):
            let fx: Fx<NotebookAction> = Just(
                NotebookAction.requestDetail(
                    slug: entryLink.slug,
                    fallback: entryLink.title,
                    autofocus: false
                )
            )
            // Request detail AFTER animaiton completes
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        case .search(let entryLink):
            let fx: Fx<NotebookAction> = Just(
                NotebookAction.requestDetail(
                    slug: entryLink.slug,
                    fallback: entryLink.title,
                    // Autofocus note because we're creating it from scratch
                    autofocus: true
                )
            )
            // Request detail AFTER animaiton completes
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        case .journal(let entryLink):
            let fx: Fx<NotebookAction> = Just(
                NotebookAction.requestTemplateDetail(
                    slug: entryLink.slug,
                    template: Config.default.journalTemplate,
                    // Autofocus note because we're creating it from scratch
                    autofocus: true
                )
            )
            // Request detail AFTER animaiton completes
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        case .scratch(let entryLink):
            let fx: Fx<NotebookAction> = Just(
                NotebookAction.requestDetail(
                    slug: entryLink.slug,
                    fallback: entryLink.title,
                    autofocus: true
                )
            )
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        case .random:
            let fx: Fx<NotebookAction> = Just(
                NotebookAction.requestRandomDetail(autofocus: false)
            )
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        }
    }
}

//  MARK: Cursors

/// Cursor for local copy of app focus
struct NotebookFocusCursor: CursorProtocol {
    static func get(state: NotebookModel) -> AppFocusModel {
        state.focus
    }

    static func set(
        state: NotebookModel,
        inner: AppFocusModel
    ) -> NotebookModel {
        var model = state
        model.focus = inner
        return model
    }

    /// Tag notebook focus actions.
    /// - Unboxes focus actions so we can forward them to
    ///   multiple sub-components.
    static func tag(action: AppFocusAction) -> NotebookAction {
        switch action {
        case .focusChange(let focus):
            return .focusChange(focus)
        case .focusRequestScheduled:
            return .focusRequestScheduled
        case .requestFocus(let focus):
            return .requestFocus(focus)
        }
    }
}

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

    static func tag(action: DetailAction) -> NotebookAction {
        switch action {
        case .refreshAll:
            return .refreshAll
        case .showDetail(let isShowing):
            return .showDetail(isShowing)
        case .openEditorURL(let url):
            return .openEditorURL(url)
        case .selectBacklink(let link):
            return .requestDetail(
                slug: link.slug,
                fallback: link.linkableTitle,
                autofocus: false
            )
        case .requestConfirmDelete(let slug):
            return .confirmDelete(slug)
        default:
            return .detail(action)
        }
    }
}

//  MARK: View
/// The file view for notes
struct NotebookView: View {
    var store: ViewStore<NotebookModel, NotebookAction>

    var isFabPresented: Bool {
        store.state.focus.focus == nil
    }

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
            GeometryReader { geometry in
                Color.background
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(0)
                AppNavigationView(store: store)
                    .zIndex(1)
                PinTrailingBottom(
                    content: Button(
                        action: {
                            store.send(.showSearch)
                        },
                        label: {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 20))
                        }
                    )
                    .buttonStyle(
                        FABButtonStyle(
                            orbShaderEnabled: Config.default.orbShaderEnabled
                        )
                    )
                    .padding()
                    .disabled(!isFabPresented)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .zIndex(2)
                ModalView(
                    isPresented: store.binding(
                        get: \.isSearchShowing,
                        tag: { _ in NotebookAction.hideSearch }
                    ),
                    content: SearchView(
                        placeholder: "Search or create...",
                        text: store.binding(
                            get: \.searchText,
                            tag: NotebookAction.setSearch
                        ),
                        focus: store.binding(
                            get: \.focus.focus,
                            tag: NotebookAction.requestFocus
                        ),
                        suggestions: store.binding(
                            get: \.suggestions,
                            tag: NotebookAction.setSuggestions
                        ),
                        onSelect: { suggestion in
                            store.send(.selectSuggestion(suggestion))
                        },
                        onSubmit: { query in
                            store.send(.submitSearch(query))
                        },
                        onCancel: {
                            store.send(.hideSearch)
                        }
                    ),
                    keyboardHeight: store.state.keyboardEventualHeight
                )
                .zIndex(3)
            }
        }
        .background(.red)
        .environment(\.openURL, OpenURLAction { url in
            store.send(.openURL(url))
            return .handled
        })
    }
}
