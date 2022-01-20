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
enum AppAction {
    case noop
    case appear
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
    case confirmDelete(String)
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
    case renameEntry(from: Slug?, to: Slug)
    /// Rename entry succeeded. Lifecycle action.
    case renameEntrySuccess(from: Slug, to: Slug)
    /// Rename entry failed. Lifecycle action.
    case renameEntryFailure(String)

    // Search
    case setSearch(String)
    case showSearch
    case hideSearch
    // Commit a search with query and slug (typically via suggestion)
    case commit(query: String, slug: Slug)

    // Search suggestions
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)

    // Detail
    case setDetail(ResultSet)
    case detailFailure(String)
    case setDetailShowing(Bool)

    // Editor
    case setEditorAttributedText(NSAttributedString)
    case setEditorSelection(NSRange)

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearch(String)
    case commitLinkSearch(String)
    case setLinkSuggestions([Suggestion])
    case linkSuggestionsFailure(String)

    // Saving entries
    case save
    case saveSuccess(Slug)
    case saveFailure(
        slug: Slug,
        message: String
    )

    /// Create a "commit" action with only a query and no slug.
    /// Used as a shorthand for search commits that aren't issued from suggestions.
    static func commitSearch(query: String) -> Self {
        AppAction.commit(
            query: query,
            // Since we don't have a slug, derive slug from query
            slug: query.slugify()
        )
    }
}

//  MARK: Model
struct AppModel {
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

    /// Committed search bar query text
    var query = ""
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
    var linkSearchQuery = ""
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
        action: AppAction
    ) -> Change<AppModel, AppAction> {
        switch action {
        case .noop:
            return Change(state: state)
        case .appear:
            return appear(state: state)
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
            return databaseReady(state: state, success: success)
        case .rebuildDatabase:
            return rebuildDatabase(state: state)
        case let .rebuildDatabaseFailure(error):
            AppEnvironment.logger.warning(
                "Could not rebuild database: \(error)"
            )
            return Change(state: state)
        case let .syncSuccess(changes):
            AppEnvironment.logger.debug(
                "File sync finished: \(changes)"
            )
            return Change(state: state)
        case let .syncFailure(message):
            AppEnvironment.logger.warning(
                "File sync failed: \(message)"
            )
            return Change(state: state)
        case .refreshAll:
            return refreshAll(state: state)
        case let .createSearchHistoryItem(query):
            return createSearchHistoryItem(
                state: state,
                query: query
            )
        case let .createSearchHistoryItemSuccess(query):
            return createSearchHistoryItemSuccess(
                state: state,
                query: query
            )
        case let .createSearchHistoryItemFailure(error):
            return createSearchHistoryItemFailure(
                state: state,
                error: error
            )
        case .listRecent:
            return listRecent(state: state)
        case let .setRecent(entries):
            var model = state
            model.recent = entries
            return Change(state: model)
        case let .listRecentFailure(error):
            AppEnvironment.logger.warning(
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
            return deleteEntry(state: state, slug: slug)
        case let .deleteEntrySuccess(slug):
            return deleteEntrySuccess(state: state, slug: slug)
        case let .deleteEntryFailure(error):
            AppEnvironment.logger.log("Failed to delete entry: \(error)")
            return Change(state: state)
        case let .showRenameSheet(slug):
            return showRenameSheet(state: state, slug: slug)
        case .hideRenameSheet:
            return hideRenameSheet(state: state)
        case let .setRenameSlugField(text):
            return setRenameSlugField(state: state, text: text)
        case let .setRenameSuggestions(suggestions):
            return setRenameSuggestions(state: state, suggestions: suggestions)
        case let .renameSuggestionsFailure(error):
            return renameSuggestionsError(state: state, error: error)
        case let .renameEntry(from, to):
            return renameEntry(state: state, from: from, to: to)
        case let .renameEntrySuccess(from, to):
            return renameEntrySuccess(state: state, from: from, to: to)
        case let .renameEntryFailure(error):
            return renameEntryFailure(state: state, error: error)
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
        case let .setDetailShowing(isShowing):
            var model = state
            model.isDetailShowing = isShowing
            if isShowing == false {
                model.focus = nil
            }
            return Change(state: model)
        case let .setSearch(text):
            return setSearch(state: state, text: text)
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
            AppEnvironment.logger.debug(
                "Suggest failed: \(message)"
            )
            return Change(state: state)
        case let .commit(query, slug):
            return commit(state: state, query: query, slug: slug)
        case let .setDetail(results):
            var model = state
            model.query = results.query
            model.slug = results.slug
            model.backlinks = results.backlinks
            model.editorAttributedText = renderMarkup(
                markup: results.entry?.content ?? results.query
            )
            return Change(state: model)
        case let .detailFailure(message):
            AppEnvironment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return Change(state: state)
        case let .setLinkSheetPresented(isPresented):
            var model = state
            model.focus = isPresented ? .linkSearch : nil
            model.isLinkSheetPresented = isPresented
            return Change(state: model)
        case let .setLinkSearch(text):
            return setLinkSearch(state: state, text: text)
        case let .commitLinkSearch(text):
            return commitLinkSearch(state: state, text: text)
        case let .setLinkSuggestions(suggestions):
            var model = state
            model.linkSuggestions = suggestions
            return Change(state: model)
        case let .linkSuggestionsFailure(message):
            AppEnvironment.logger.debug(
                "Link suggest failed: \(message)"
            )
            return Change(state: state)
        case .save:
            return save(state: state)
        case let .saveSuccess(slug):
            return saveSuccess(state: state, slug: slug)
        case let .saveFailure(url, message):
            //  TODO: show user a "try again" banner
            AppEnvironment.logger.warning(
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

    static func appear(state: AppModel) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.debug(
            "Documents: \(AppEnvironment.documentURL)"
        )
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .migrate()
            .map({ success in
                AppAction.databaseReady(success)
            })
            .catch({ _ in
                Just(AppAction.rebuildDatabase)
            })
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
                    AppAction.commitSearch(
                        query: Slashlink.urlToProse(url)
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
        success: SQLite3Migrations.MigrationSuccess
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.isDatabaseReady = true
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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
            AppEnvironment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        AppEnvironment.logger.log("File sync started")
        return Change(state: model, fx: fx)
    }

    static func rebuildDatabase(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .delete()
            .flatMap({ _ in
                AppEnvironment.database.migrate()
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
        query: String
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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
        query: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.log(
            "Created search history entry: \(query)"
        )
        return Change(state: state)
    }

    /// Handle failure case for search history item creation
    static func createSearchHistoryItemFailure(
        state: AppModel,
        error: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.warning(
            "Failed to create search history entry: \(error)"
        )
        return Change(state: state)
    }

    static func listRecent(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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
        slug: Slug
    ) -> Change<AppModel, AppAction> {
        var model = state
        if let index = model.recent.firstIndex(
            where: { stub in stub.id == slug }
        ) {
            model.recent.remove(at: index)
            let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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
            AppEnvironment.logger.log(
                "Failed to delete entry. No such id: \(slug)"
            )
            return Change(state: model)
        }
    }

    static func deleteEntrySuccess(
        state: AppModel,
        slug: Slug
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.log("Deleted entry: \(slug)")
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
        slug: Slug?
    ) -> Change<AppModel, AppAction> {
        if let slug = slug {
            let fx: AnyPublisher<AppAction, Never> = Just(
                AppAction.setRenameSlugField(slug)
            )
            .merge(with: Just(AppAction.setFocus(.rename)))
            .eraseToAnyPublisher()

            var model = state
            model.isRenameSheetShowing = true
            model.slugToRename = slug

            return Change(state: model, fx: fx)
        } else {
            AppEnvironment.logger.warning(
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
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.renameSlugField = text
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .searchRenameSuggestions(query: text, current: state.slugToRename)
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
        error: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.warning(
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
        to: Slug
    ) -> Change<AppModel, AppAction> {
        guard !to.isWhitespace else {
            let fx: AnyPublisher<AppAction, Never> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            AppEnvironment.logger.log(
                "Rename invoked with whitespace name. Cancelling."
            )
            return Change(state: state, fx: fx)
        }

        guard from != nil else {
            let fx: AnyPublisher<AppAction, Never> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            AppEnvironment.logger.warning(
                "Tried to rename entry but no slug was given. Current: nil. Next: \(to)"
            )
            return Change(state: state, fx: fx)
        }

        guard from != to else {
            let fx: AnyPublisher<AppAction, Never> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            AppEnvironment.logger.log(
                "Rename invoked with same name. Cancelling."
            )
            return Change(state: state, fx: fx)
        }

        let from = from!
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .renameEntry(from: from, to: to)
            .map({ _ in
                AppAction.renameEntrySuccess(from: from, to: to)
            })
            .catch({ error in
                Just(
                    AppAction.renameEntryFailure(
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
    static func renameEntrySuccess(
        state: AppModel,
        from: Slug,
        to: Slug
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.log("Renamed entry from \(from) to \(to)")
        // TODO: figure out what FX to generate
        // TODO: figure out what state to change
        return Change(state: state)
    }

    static func renameEntryFailure(
        state: AppModel,
        error: String
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.warning(
            "Failed to rename entry with error: \(error)"
        )
        // TODO: figure out what FX to generate
        return Change(state: state)
    }

    static func setSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.searchText = text
        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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

    static func commit(
        state: AppModel,
        query: String,
        slug: Slug
    ) -> Change<AppModel, AppAction> {
        var model = resetEditor(state: state)
        model.slug = nil
        model.searchText = ""
        model.isSearchShowing = false
        model.isDetailShowing = true

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
            .search(
                query: query,
                slug: slug
            )
            .map({ results in
                AppAction.setDetail(results)
            })
            .catch({ error in
                Just(AppAction.detailFailure(error.localizedDescription))
            })
            .merge(
                with: Just(AppAction.setSearch("")),
                Just(AppAction.createSearchHistoryItem(query))
            )
            .eraseToAnyPublisher()

        return Change(state: model, fx: fx)
    }

    static func setLinkSearch(
        state: AppModel,
        text: String
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.linkSearchText = text

        let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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

    static func commitLinkSearch(state: AppModel, text: String) -> Change<AppModel, AppAction> {
        var model = state
        if let range = Range(
            model.editorSelection,
            in: state.editorAttributedText.string
        ) {
            // Replace selected range with committed link search text.
            let markup = state.editorAttributedText.string
                .replacingCharacters(
                    in: range,
                    with: text
                )
            // Re-render and assign
            model.editorAttributedText = renderMarkup(markup: markup)
            // Find inserted range by searching for our inserted text
            // AFTER the cursor position.
            if let insertedRange = markup.range(
                of: text,
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
        model.linkSearchQuery = text
        model.linkSearchText = ""
        model.focus = nil
        model.isLinkSheetPresented = false
        return Change(state: model)
    }

    /// Save entry to database
    static func save(
        state: AppModel
    ) -> Change<AppModel, AppAction> {
        var model = state
        model.focus = nil
        if let slug = model.slug {
            // Parse editorAttributedText to entry.
            // TODO refactor model to store entry instead of attributedText.
            let entry = SubtextFile(
                slug: slug,
                content: model.editorAttributedText.string
            )
            let fx: AnyPublisher<AppAction, Never> = AppEnvironment.database
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
            AppEnvironment.logger.warning(
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
        slug: Slug
    ) -> Change<AppModel, AppAction> {
        AppEnvironment.logger.debug(
            "Saved entry: \(slug)"
        )
        let fx = Just(AppAction.refreshAll)
            .eraseToAnyPublisher()
        return Change(state: state, fx: fx)
    }
}

//  MARK: View
struct AppView: View {
    @ObservedObject var store: Store<AppModel, AppAction>

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
                            withAnimation(.easeOut(duration: Duration.fast)) {
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
                if store.state.isSearchShowing {
                    SearchView(
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
                        onCommit: { query, slug in
                            if let slug = slug {
                                store.send(
                                    action: .commit(
                                        query: query,
                                        slug: slug
                                    )
                                )
                            } else {
                                store.send(
                                    action: .commitSearch(query: query)
                                )
                            }
                        },
                        onCancel: {
                            withAnimation(.easeOut(duration: Duration.fast)) {
                                store.send(
                                    action: .hideSearch
                                )
                            }
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion:
                                .move(edge: .bottom)
                                .combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                    .zIndex(3)
                }
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
