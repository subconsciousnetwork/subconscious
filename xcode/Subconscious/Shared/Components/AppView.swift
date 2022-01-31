//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os
import Combine

//  MARK: Actions
/// Actions for modifying state
/// For action naming convention, see
/// https://github.com/gordonbrander/subconscious/wiki/action-naming-convention
enum AppAction {
    case noop

    //  KeyboardService
    case changeKeyboardState(KeyboardState)

    //  Lifecycle events
    case appear

    //  URL handlers
    case openURL(URL)
    case openEditorURL(url: URL, range: NSRange)

    // Focus state for TextFields, TextViews, etc
    case setFocus(AppModel.Focus?)

    // Database
    case databaseReady(SQLite3Migrations.MigrationSuccess)
    case rebuildDatabase
    case rebuildDatabaseFailure(String)
    case syncSuccess([FileSync.Change])
    case syncFailure(String)

    /// Refresh the state of all lists by reloading from database.
    /// This also sets searches to their zero-query state.
    case refreshAll

    //  Search history
    /// Write a search history event to the database
    case createSearchHistoryItem(String)
    case createSearchHistoryItemSuccess(String)
    case createSearchHistoryItemFailure(String)

    // List entries
    case listRecent
    case setRecent([EntryStub])
    case listRecentFailure(String)

    // Delete entries
    case confirmDelete(Slug)
    case setConfirmDeleteShowing(Bool)
    case deleteEntry(Slug)
    case deleteEntrySuccess(Slug)
    case deleteEntryFailure(String)

    // Rename
    case showRenameSheet(Slug?)
    case hideRenameSheet
    case setRenameSlugField(String)
    case setRenameSuggestions([Suggestion])
    case renameSuggestionsFailure(String)
    /// Issue a rename action for an entry.
    case renameEntry(from: Slug?, to: Slug?)
    /// Rename entry succeeded. Lifecycle action.
    case succeedRenameEntry(from: Slug, to: Slug)
    /// Rename entry failed. Lifecycle action.
    case failRenameEntry(String)

    //  Search
    /// Set search text (updated live as you type)
    case setSearch(String)
    /// Submit search query (e.g. by hitting enter)
    case submitSearch(slug: Slug?, query: String)
    case showSearch
    case hideSearch

    // Search suggestions
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)

    // Detail
    case requestDetail(slug: Slug?, fallback: String)
    case updateDetail(EntryDetail)
    case failDetail(String)
    case showDetail(Bool)

    // Editor
    case setEditorAttributedText(NSAttributedString)
    case setEditorSelection(NSRange)

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearch(String)
    case commitLinkSearch(Slug)
    case setLinkSuggestions([Suggestion])
    case linkSuggestionsFailure(String)

    // Saving entries
    case save
    case saveSuccess(Slug)
    case saveFailure(
        slug: Slug,
        message: String
    )
}

//  MARK: Model
struct AppModel: Hashable, Equatable {
    /// Enum describing which view is currently focused.
    /// Focus is mutually exclusive, and SwiftUI's FocusedState requires
    /// modeling this state as an enum.
    /// See https://github.com/gordonbrander/subconscious/wiki/SwiftUI-FocusState
    /// 2021-12-23 Gordon Brander
    enum Focus: Hashable, Equatable {
        case search
        case linkSearch
        case editor
        case rename
    }

    /// Current state of keyboard
    var keyboardWillShow = false
    var keyboardEventualHeight: CGFloat = 0

    /// What is focused? (nil means nothing is focused)
    var focus: Focus? = nil

    /// Is database connected and migrated?
    var isDatabaseReady = false
    /// Is the detail view (edit and details for an entry) showing?
    var isDetailShowing = false

    //  Recent entries
    var recent: [EntryStub] = []

    //  Note deletion action sheet
    /// Delete confirmation action sheet
    var entryToDelete: Slug? = nil
    /// Delete confirmation action sheet
    var isConfirmDeleteShowing = false

    //  Note renaming
    /// Is rename sheet showing?
    var isRenameSheetShowing = false
    /// Slug of the candidate for renaming
    var slugToRename: Slug? = nil
    /// Text for slug rename TextField.
    /// Note this is the contents of the search text field, which
    /// is different from the actual candidate slug to be renamed.
    var renameSlugField: String = ""
    /// Suggestions for renaming note.
    var renameSuggestions: [Suggestion] = []

    /// Live search bar text
    var searchText = ""
    var isSearchShowing = false

    /// Slug for the currently selected entry
    var slug: Slug? = nil

    /// Main search suggestions
    var suggestions: [Suggestion] = []

    // Editor
    var editorAttributedText = NSAttributedString("")
    /// Editor selection corresponds with `editorAttributedText`
    var editorSelection = NSMakeRange(0, 0)

    /// Backlinks to the currently active entry
    var backlinks: [EntryStub] = []

    /// Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var linkSearchText = ""
    var linkSuggestions: [Suggestion] = []
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
struct AppUpdate {
    static func update(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        switch action {
        case .noop:
            return Change(state: state)
        case let .changeKeyboardState(keyboard):
            return changeKeyboardState(state: state, keyboard: keyboard)
        case .appear:
            return appear(state: state, environment: environment)
        case let .openURL(url):
            UIApplication.shared.open(url)
            return Change(state: state)
        case let .openEditorURL(url, range):
            return openEditorURL(state: state, url: url, range: range)
        case let .setFocus(focus):
            var model = state
            model.focus = focus
            return Change(state: model)
        case let .databaseReady(success):
            return databaseReady(
                state: state,
                success: success,
                environment: environment
            )
        case .rebuildDatabase:
            return rebuildDatabase(
                state: state,
                environment: environment
            )
        case let .rebuildDatabaseFailure(error):
            environment.logger.warning(
                "Could not rebuild database: \(error)"
            )
            return Change(state: state)
        case let .syncSuccess(changes):
            environment.logger.debug(
                "File sync finished: \(changes)"
            )
            return Change(state: state)
        case let .syncFailure(message):
            environment.logger.warning(
                "File sync failed: \(message)"
            )
            return Change(state: state)
        case .refreshAll:
            return refreshAll(state: state)
        case let .createSearchHistoryItem(query):
            return createSearchHistoryItem(
                state: state,
                query: query,
                environment: environment
            )
        case let .createSearchHistoryItemSuccess(query):
            return createSearchHistoryItemSuccess(
                state: state,
                query: query,
                environment: environment
            )
        case let .createSearchHistoryItemFailure(error):
            return createSearchHistoryItemFailure(
                state: state,
                error: error,
                environment: environment
            )
        case .listRecent:
            return listRecent(
                state: state,
                environment: environment
            )
        case let .setRecent(entries):
            var model = state
            model.recent = entries
            return Change(state: model)
        case let .listRecentFailure(error):
            environment.logger.warning(
                "Failed to list recent entries: \(error)"
            )
            return Change(state: state)
        case let .confirmDelete(slug):
            var model = state
            model.entryToDelete = slug
            model.isConfirmDeleteShowing = true
            return Change(state: model)
        case let .setConfirmDeleteShowing(isShowing):
            var model = state
            model.isConfirmDeleteShowing = isShowing
            // Reset entry to delete if we're dismissing the confirmation
            // dialog.
            if isShowing == false {
                model.entryToDelete = nil
            }
            return Change(state: model)
        case let .deleteEntry(slug):
            return deleteEntry(
                state: state,
                slug: slug,
                environment: environment
            )
        case let .deleteEntrySuccess(slug):
            return deleteEntrySuccess(
                state: state,
                slug: slug,
                environment: environment
            )
        case let .deleteEntryFailure(error):
            environment.logger.log("Failed to delete entry: \(error)")
            return Change(state: state)
        case let .showRenameSheet(slug):
            return showRenameSheet(
                state: state,
                slug: slug,
                environment: environment
            )
        case .hideRenameSheet:
            return hideRenameSheet(state: state)
        case let .setRenameSlugField(text):
            return setRenameSlugField(
                state: state,
                text: text,
                environment: environment
            )
        case let .setRenameSuggestions(suggestions):
            return setRenameSuggestions(state: state, suggestions: suggestions)
        case let .renameSuggestionsFailure(error):
            return renameSuggestionsError(
                state: state,
                error: error,
                environment: environment
            )
        case let .renameEntry(from, to):
            return renameEntry(
                state: state,
                from: from,
                to: to,
                environment: environment
            )
        case let .succeedRenameEntry(from, to):
            return succeedRenameEntry(
                state: state,
                from: from,
                to: to,
                environment: environment
            )
        case let .failRenameEntry(error):
            return failRenameEntry(
                state: state,
                error: error,
                environment: environment
            )
        case let .setEditorAttributedText(attributedText):
            var model = state
            // Render attributes from markup if text has changed
            if !state.editorAttributedText.isEqual(to: attributedText) {
                // Rerender attributes from markup, then assign to
                // model.
                model.editorAttributedText = renderMarkup(
                    markup: attributedText.string
                )
            }
            return Change(state: model)
        case let .setEditorSelection(range):
            var model = state
            model.editorSelection = range
            return Change(state: model)
        case let .showDetail(isShowing):
            var model = state
            model.isDetailShowing = isShowing
            if isShowing == false {
                model.focus = nil
            }
            return Change(state: model)
        case let .setSearch(text):
            return setSearch(
                state: state,
                text: text,
                environment: environment
            )
        case let .submitSearch(slug, query):
            return submitSearch(state: state, slug: slug, query: query)
        case .showSearch:
            var model = state
            model.isSearchShowing = true
            model.searchText = ""
            model.focus = .search
            return Change(state: model)
        case .hideSearch:
            var model = state
            model.isSearchShowing = false
            model.searchText = ""
            model.focus = nil
            return Change(state: model)
        case let .setSuggestions(suggestions):
            var model = state
            model.suggestions = suggestions
            return Change(state: model)
        case let .suggestionsFailure(message):
            environment.logger.debug(
                "Suggest failed: \(message)"
            )
            return Change(state: state)
        case let .requestDetail(slug, fallback):
            return requestDetail(
                state: state,
                slug: slug,
                fallback: fallback,
                environment: environment
            )
        case let .updateDetail(results):
            var model = state
            model.slug = results.slug
            model.backlinks = results.backlinks
            model.editorAttributedText = renderMarkup(
                markup: results.entry.content
            )
            return Change(state: model)
        case let .failDetail(message):
            environment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return Change(state: state)
        case let .setLinkSheetPresented(isPresented):
            var model = state
            model.focus = isPresented ? .linkSearch : .editor
            model.isLinkSheetPresented = isPresented
            return Change(state: model)
        case let .setLinkSearch(text):
            return setLinkSearch(
                state: state,
                text: text,
                environment: environment
            )
        case let .commitLinkSearch(slug):
            return commitLinkSearch(state: state, slug: slug)
        case let .setLinkSuggestions(suggestions):
            var model = state
            model.linkSuggestions = suggestions
            return Change(state: model)
        case let .linkSuggestionsFailure(message):
            environment.logger.debug(
                "Link suggest failed: \(message)"
            )
            return Change(state: state)
        case .save:
            return save(
                state: state,
                environment: environment
            )
        case let .saveSuccess(slug):
            return saveSuccess(
                state: state,
                slug: slug,
                environment: environment
            )
        case let .saveFailure(url, message):
            //  TODO: show user a "try again" banner
            environment.logger.warning(
                "Save failed for entry (\(url)) with error: \(message)"
            )
            return Change(state: state)
        }
    }

    static func renderMarkup(
        markup: String
    ) -> NSAttributedString {
        Subtext(markup: markup)
            .renderMarkup(url: Slashlink.slashlinkToURLString)
    }

    /// Set all editor properties to initial values
    static func resetEditor(state: AppModel) -> AppModel {
        var model = state
        model.editorAttributedText = NSAttributedString("")
        model.editorSelection = NSMakeRange(0, 0)
        model.focus = nil
        return model
    }

    /// Change state of keyboard
    /// Actions come from `KeyboardService`
    static func changeKeyboardState(
        state: AppModel,
        keyboard: KeyboardState
    ) -> Change<AppModel, AppAction> {
        switch keyboard {
        case
            .willShow(let size, _),
            .didShow(let size),
            .didChangeFrame(let size):
            var model = state
            model.keyboardWillShow = true
            model.keyboardEventualHeight = size.height
            return Change(state: model)
        case .willHide:
            return Change(state: state)
        case .didHide:
            var model = state
            model.keyboardWillShow = false
            model.keyboardEventualHeight = 0
            return Change(state: model)
        }
    }

    static func appear(
        state: AppModel,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.debug(
            "Documents: \(environment.documentURL)"
        )

        // Subscribe to keyboard events
        let keyboardFx: AnyPublisher<AppAction, Never> = environment
            .keyboard.state
            .map({ value in
                AppAction.changeKeyboardState(value)
            })
            .eraseToAnyPublisher()

        let fx: AnyPublisher<AppAction, Never> = environment.database
            .migrate()
            .map({ success in
                AppAction.databaseReady(success)
            })
            .catch({ _ in
                Just(AppAction.rebuildDatabase)
            })
            .merge(with: keyboardFx)
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    static func openEditorURL(
        state: AppModel,
        url: URL,
        range: NSRange
    ) -> Change<AppModel, AppAction> {
        // Don't follow links while editing. Instead, select the link.
        //
        // When editing, you usually don't want to follow a link, you
        // want to tap into it to edit it. Also, we don't want to follow a
        // link in the middle of an edit and lose changes.
        //
        // Other approaches we could take in future:
        // - Save before following
        // - Have a disclosure step before following (like Google Docs)
        // For now, I think this is the best approach.
        //
        // 2021-09-23 Gordon Brander
        if state.focus == .editor {
            let fx: AnyPublisher<AppAction, Never> = Just(
                AppAction.setEditorSelection(range)
            ).eraseToAnyPublisher()
            return Change(state: state, fx: fx)
        } else {
            if Slashlink.isSlashlinkURL(url) {
                // If this is a Subtext URL, then commit a search for the
                // corresponding query
                let fx: AnyPublisher<AppAction, Never> = Just(
                    AppAction.requestDetail(
                        slug: Slashlink.slashlinkURLToSlug(url),
                        fallback: ""
                    )
                ).eraseToAnyPublisher()
                return Change(state: state, fx: fx)
            } else {
                UIApplication.shared.open(url)
                return Change(state: state)
            }
        }
    }

    static func databaseReady(
        state: AppModel,
        success: SQLite3Migrations.MigrationSuccess,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.isDatabaseReady = true
        let fx: AnyPublisher<AppAction, Never> = environment.database
            .syncDatabase()
            .map({ changes in
                AppAction.syncSuccess(changes)
            })
            .catch({ error in
                Just(AppAction.syncFailure(error.localizedDescription))
            })
            .merge(with: Just(.refreshAll))
            .eraseToAnyPublisher()
        if success.from != success.to {
            environment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        environment.logger.log("File sync started")
        return Change(state: model, fx: fx)
    }

    static func rebuildDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        let fx: AnyPublisher<AppAction, Never> = environment.database
            .delete()
            .flatMap({ _ in
                environment.database.migrate()
            })
            .map({ success in
                AppAction.databaseReady(success)
            })
            .catch({ error in
                Just(AppAction.rebuildDatabaseFailure(
                    error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    /// Refresh all lists in the app from database
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshAll(state: AppModel) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = Just(AppAction.listRecent)
            .merge(
                with: Just(AppAction.setSearch("")),
                Just(AppAction.setLinkSearch(""))
            )
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    /// Insert search history event into database
    static func createSearchHistoryItem(
        state: AppModel,
        query: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = environment.database
            .createSearchHistoryItem(query: query)
            .map({ result in
                AppAction.noop
            })
            .catch({ error in
                Just(
                    AppAction.createSearchHistoryItemFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    /// Handle success case for search history item creation
    static func createSearchHistoryItemSuccess(
        state: AppModel,
        query: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.log(
            "Created search history entry: \(query)"
        )
        return Change(state: state)
    }

    /// Handle failure case for search history item creation
    static func createSearchHistoryItemFailure(
        state: AppModel,
        error: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.warning(
            "Failed to create search history entry: \(error)"
        )
        return Change(state: state)
    }

    static func listRecent(
        state: AppModel,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = environment.database
            .listRecentEntries()
            .map({ entries in
                AppAction.setRecent(entries)
            })
            .catch({ error in
                Just(
                    .listRecentFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    static func deleteEntry(
        state: AppModel,
        slug: Slug,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        var model = state
        if let index = model.recent.firstIndex(
            where: { stub in stub.id == slug }
        ) {
            model.recent.remove(at: index)
            let fx: AnyPublisher<AppAction, Never> = environment.database
                .deleteEntry(slug: slug)
                .map({ _ in
                    AppAction.deleteEntrySuccess(slug)
                })
                .catch({ error in
                    Just(
                        AppAction.deleteEntryFailure(
                            error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()
            return Change(state: model, fx: fx)
        } else {
            environment.logger.log(
                "Failed to delete entry. No such id: \(slug)"
            )
            return Change(state: model)
        }
    }

    static func deleteEntrySuccess(
        state: AppModel,
        slug: Slug,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.log("Deleted entry: \(slug)")
        //  Refresh lists in search fields after delete.
        //  This ensures they don't show the deleted entry.
        let fx: AnyPublisher<AppAction, Never> = Just(AppAction.refreshAll)
            .eraseToAnyPublisher()
        return Change(
            state: state,
            fx: fx
        )
    }

    /// Show rename sheet.
    /// Do rename-flow-related setup.
    static func showRenameSheet(
        state: AppModel,
        slug: Slug?,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        if let slug = slug {
            //  Set rename slug field text
            //  Set focus on rename field
            //  Save entry in preperation for any merge/move.
            let fx: AnyPublisher<AppAction, Never> = Just(
                AppAction.setRenameSlugField(slug.description)
            )
            .merge(
                with: Just(AppAction.setFocus(.rename)),
                Just(AppAction.save)
            )
            .eraseToAnyPublisher()

            var model = state
            model.isRenameSheetShowing = true
            model.slugToRename = slug

            return Change(state: model, fx: fx)
        } else {
            environment.logger.warning(
                "Rename sheet invoked with nil slug"
            )
            return Change(state: state)
        }
    }

    /// Hide rename sheet.
    /// Do rename-flow-related teardown.
    static func hideRenameSheet(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = Just(
            AppAction.setRenameSlugField("")
        ).eraseToAnyPublisher()

        var model = state
        model.isRenameSheetShowing = false
        model.slugToRename = nil

        return Change(state: model, fx: fx)
    }

    /// Set text of slug field
    static func setRenameSlugField(
        state: AppModel,
        text: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        var model = state
        let sluglike = Slug.toSluglikeString(text)
        model.renameSlugField = sluglike
        let fx: AnyPublisher<AppAction, Never> = environment.database
            .searchRenameSuggestions(
                query: sluglike,
                current: state.slugToRename
            )
            .map({ suggestions in
                AppAction.setRenameSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    AppAction.renameSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Change(state: model, fx: fx)
    }

    /// Set rename suggestions
    static func setRenameSuggestions(
        state: AppModel,
        suggestions: [Suggestion]
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.renameSuggestions = suggestions
        return Change(state: model)
    }

    /// Handle rename suggestions error.
    /// This case can happen e.g. if the database fails to respond.
    static func renameSuggestionsError(
        state: AppModel,
        error: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.warning(
            "Failed to read suggestions from database: \(error)"
        )
        return Change(state: state)
    }

    /// Rename an entry (change its slug).
    /// If `next` does not already exist, this will change the slug
    /// and move the file.
    /// If next exists, this will merge documents.
    static func renameEntry(
        state: AppModel,
        from: Slug?,
        to: Slug?,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        guard let to = to else {
            let fx: AnyPublisher<AppAction, Never> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            environment.logger.log(
                "Rename invoked with whitespace name. Doing nothing."
            )
            return Change(state: state, fx: fx)
        }

        guard let from = from else {
            let fx: AnyPublisher<AppAction, Never> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            environment.logger.warning(
                "Rename invoked without original slug. Doing nothing. Current: nil. Next: \(to)."
            )
            return Change(state: state, fx: fx)
        }

        guard from != to else {
            let fx: AnyPublisher<AppAction, Never> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            environment.logger.log(
                "Rename invoked with same name. Doing nothing."
            )
            return Change(state: state, fx: fx)
        }

        let fx: AnyPublisher<AppAction, Never> = environment.database
            .renameOrMergeEntry(from: from, to: to)
            .map({ _ in
                AppAction.succeedRenameEntry(from: from, to: to)
            })
            .catch({ error in
                Just(
                    AppAction.failRenameEntry(
                        error.localizedDescription
                    )
                )
            })
            .merge(with: Just(AppAction.hideRenameSheet))
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    /// Rename success lifecycle handler.
    /// Updates UI in response.
    static func succeedRenameEntry(
        state: AppModel,
        from: Slug,
        to: Slug,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.log("Renamed entry from \(from) to \(to)")
        let fx: AnyPublisher<AppAction, Never> = Just(
            AppAction.requestDetail(slug: to, fallback: "")
        )
        .merge(with: Just(AppAction.refreshAll))
        .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    /// Rename failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failRenameEntry(
        state: AppModel,
        error: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.warning(
            "Failed to rename entry with error: \(error)"
        )
        return Change(state: state)
    }

    /// Set search text for main search input
    static func setSearch(
        state: AppModel,
        text: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.searchText = text
        let fx: AnyPublisher<AppAction, Never> = environment.database
            .searchSuggestions(query: text)
            .map({ suggestions in
                AppAction.setSuggestions(suggestions)
            })
            .catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Change(state: model, fx: fx)
    }

    /// Submit search from main search input
    static func submitSearch(
        state: AppModel,
        slug: Slug?,
        query: String
    ) -> Change<AppModel, AppAction> {
        guard let slug = slug else {
            return Change(state: state)
        }
        // If we have been passed a valid slug, request a detail view.
        let fx: AnyPublisher<AppAction, Never> = Just(
            AppAction.requestDetail(
                slug: slug,
                fallback: query
            )
        ).eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }

    /// Request that entry detail view be shown
    static func requestDetail(
        state: AppModel,
        slug: Slug?,
        fallback: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        /// If nil slug was requested, do nothing
        guard let slug = slug else {
            return Change(state: state)
        }

        var model = resetEditor(state: state)
        model.slug = nil
        model.searchText = ""
        model.isSearchShowing = false
        model.isDetailShowing = true

        let fx: AnyPublisher<AppAction, Never> = environment.database
            .readEntryDetail(slug: slug, fallback: fallback)
            .map({ results in
                AppAction.updateDetail(results)
            })
            .catch({ error in
                Just(AppAction.failDetail(error.localizedDescription))
            })
            .merge(
                with: Just(AppAction.setSearch("")),
                Just(AppAction.createSearchHistoryItem(fallback))
            )
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    static func setLinkSearch(
        state: AppModel,
        text: String,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.linkSearchText = text

        let fx: AnyPublisher<AppAction, Never> = environment.database
            .searchSuggestions(query: text)
            .map({ suggestions in
                AppAction.setLinkSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    AppAction.linkSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    static func commitLinkSearch(
        state: AppModel,
        slug: Slug
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = Just(
            AppAction.setLinkSheetPresented(false)
        ).eraseToAnyPublisher()

        var model = state
        if let range = Range(
            model.editorSelection,
            in: state.editorAttributedText.string
        ) {
            let slashlink = slug.toSlashlink()
            // Replace selected range with committed link search text.
            let markup = state.editorAttributedText.string
                .replacingCharacters(
                    in: range,
                    with: slashlink
                )
            // Re-render and assign
            model.editorAttributedText = renderMarkup(markup: markup)
            // Find inserted range by searching for our inserted text
            // AFTER the cursor position.
            if let insertedRange = markup.range(
                of: slashlink,
                range: range.lowerBound..<markup.endIndex
            ) {
                // Convert Range to NSRange of editorAttributedText,
                // assign to editorSelection.
                model.editorSelection = NSRange(
                    insertedRange,
                    in: markup
                )
            }
        }
        model.linkSearchText = ""

        return Change(state: model, fx: fx)
    }

    /// Save entry to database
    static func save(
        state: AppModel,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.focus = nil
        if let slug = model.slug {
            // Parse editorAttributedText to entry.
            let entry = SubtextFile(
                slug: slug,
                content: model.editorAttributedText.string
            )
            let fx: AnyPublisher<AppAction, Never> = environment.database
                .writeEntry(
                    entry: entry
                )
                .map({ _ in
                    AppAction.saveSuccess(slug)
                })
                .catch({ error in
                    Just(
                        AppAction.saveFailure(
                            slug: slug,
                            message: error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()
            return Change(state: model, fx: fx)
        } else {
            environment.logger.warning(
                """
                Could not save. No URL set for entry.
                It should not be possible to reach this state.
                """
            )
            return Change(state: model)
        }
    }

    /// Log save success and perform refresh of various lists.
    static func saveSuccess(
        state: AppModel,
        slug: Slug,
        environment: AppEnvironment
    ) -> Change<AppModel, AppAction> {
        environment.logger.debug(
            "Saved entry: \(slug)"
        )
        let fx = Just(AppAction.refreshAll)
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }
}

//  MARK: View
struct AppView: View {
    @ObservedObject var store: SubconsciousStore

    var body: some View {
        // Give each element in this ZStack an explicit z-index.
        // This keeps transitions working correctly.
        // SwiftUI will dynamically generate z-indexes when no explicit
        // z-index is given. This can cause transitions to layer incorrectly.
        // Adding an explicit z-index fixed problems with the
        // out-transition for the search view.
        // See https://stackoverflow.com/a/58512696
        // 2021-12-16 Gordon Brander
        ZStack(alignment: .bottomTrailing) {
            Color.background.edgesIgnoringSafeArea(.all)
            if store.state.isDatabaseReady {
                AppNavigationView(store: store)
                    .zIndex(1)
                if store.state.focus == nil {
                    Button(
                        action: {
                            withAnimation(
                                .easeOutCubic(duration: Duration.keyboard)
                            ) {
                                store.send(action: .showSearch)
                            }
                        },
                        label: {
                            Image(systemName: "plus")
                        }
                    )
                    .buttonStyle(FABButtonStyle())
                    .padding()
                    .transition(.opacity)
                    .zIndex(2)
                }
                ModalView(
                    isPresented: store.binding(
                        get: \.isSearchShowing,
                        tag: { _ in AppAction.hideSearch },
                        animation: .easeOutCubic(duration: Duration.keyboard)
                    ),
                    content: SearchView(
                        placeholder: "Search or create...",
                        text: store.binding(
                            get: \.searchText,
                            tag: AppAction.setSearch
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: AppAction.setFocus
                        ),
                        suggestions: store.binding(
                            get: \.suggestions,
                            tag: AppAction.setSuggestions
                        ),
                        onCommit: { slug, query in
                            store.send(
                                action: .submitSearch(
                                    slug: slug,
                                    query: query
                                )
                            )
                        },
                        onCancel: {
                            withAnimation(
                                .easeOutCubic(duration: Duration.keyboard)
                            ) {
                                store.send(
                                    action: .hideSearch
                                )
                            }
                        }
                    ),
                    keyboardHeight: store.state.keyboardEventualHeight
                )
                .zIndex(3)
            } else {
                ProgressScrim()
            }
        }
        .font(Font.appText)
        .onAppear {
            store.send(action: .appear)
        }
        .environment(\.openURL, OpenURLAction { url in
            store.send(action: .openURL(url))
            return .handled
        })
    }
}
