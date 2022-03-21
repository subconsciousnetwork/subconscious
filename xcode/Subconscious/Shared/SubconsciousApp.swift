//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os
import Combine
import ObservableStore

@main
struct SubconsciousApp: App {
    @StateObject private var store: AppStore = Store(
        update: AppModel.updateAndLog,
        state: AppModel(),
        environment: AppEnvironment()
    )

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}

//  MARK: Store typealias
typealias AppStore = Store<AppModel, AppEnvironment, AppAction>

//  MARK: Actions
/// Actions for modifying state
/// For action naming convention, see
/// https://github.com/gordonbrander/subconscious/wiki/action-naming-convention
enum AppAction {
    case noop

    ///  KeyboardService state change
    case changeKeyboardState(KeyboardState)

    /// Poll service
    case poll(Date)

    //  Lifecycle events
    /// When scene phase changes.
    /// E.g. when app is foregrounded, backgrounded, etc.
    case scenePhaseChange(ScenePhase)
    case appear

    //  URL handlers
    case openURL(URL)
    case openEditorURL(url: URL, range: NSRange)

    /// Focus state for TextFields, TextViews, etc
    case setFocus(AppModel.Focus?)
    /// Resign focus, if you have it
    case resignFocus(AppModel.Focus)

    //  Database
    /// Get database ready for interaction
    case readyDatabase
    case migrateDatabaseSuccess(SQLite3Migrations.MigrationSuccess)
    case rebuildDatabase
    case rebuildDatabaseFailure(String)
    /// Sync database with file system
    case sync
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

    // Rename
    case showRenameSheet(Slug?)
    case hideRenameSheet
    case setRenameSlugField(String)
    case setRenameSuggestions([RenameSuggestion])
    case renameSuggestionsFailure(String)
    /// Issue a rename action for an entry.
    case renameEntry(from: Slug?, to: RenameSuggestion)
    /// Rename entry succeeded. Lifecycle action.
    case succeedRenameEntry(from: Slug, to: Slug)
    /// Rename entry failed. Lifecycle action.
    case failRenameEntry(String)

    //  Search
    /// Set search text (updated live as you type)
    case setSearch(String)
    case showSearch
    case hideSearch

    // Search suggestions
    /// Submit search suggestion
    case selectSuggestion(Suggestion)
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)

    // Detail
    case requestDetail(slug: Slug?, fallback: String)
    case updateDetail(EntryDetail)
    case failDetail(String)
    case failRandomDetail(Error)
    case showDetail(Bool)

    // Editor
    /// Invokes save and blurs editor
    case selectDoneEditing
    /// Update editor dom and mark if this state is saved or not
    case setEditor(text: String, saveState: SaveState)
    case setEditorSelection(NSRange)
    case insertEditorText(
        text: String,
        range: NSRange
    )

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearch(String)
    case selectLinkSuggestion(LinkSuggestion)
    case setLinkSuggestions([LinkSuggestion])
    case linkSuggestionsFailure(String)

    //  Saving entries
    /// Save an entry at a particular snapshot value
    case save
    case succeedSave(SubtextFile)
    case failSave(
        slug: Slug,
        message: String
    )

    /// Update editor dom and always mark modified
    static func modifyEditor(text: String) -> Self {
        Self.setEditor(text: text, saveState: .modified)
    }
}

//  MARK: Model
struct AppModel: Equatable {
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

    enum DatabaseState {
        case initial
        case migrating
        case broken
        case ready
    }

    /// Feature flags
    var config = Config()

    /// Current state of keyboard
    var keyboardWillShow = false
    var keyboardEventualHeight: CGFloat = 0

    /// What is focused? (nil means nothing is focused)
    var focus: Focus? = nil

    /// Is database connected and migrated?
    var databaseState = DatabaseState.initial
    /// Is the detail view (edit and details for an entry) showing?
    var isDetailShowing = false

    /// Count of entries
    var entryCount: Int? = nil

    ///  Recent entries (nil means "hasn't been loaded from DB")
    var recent: [EntryStub]? = nil

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
    var renameSuggestions: [RenameSuggestion] = []

    /// Live search bar text
    var searchText = ""
    var isSearchShowing = false

    /// Slug for the currently selected entry
    var slug: Slug? = nil
    var isDetailLoading = true

    /// Main search suggestions
    var suggestions: [Suggestion] = []

    // Editor
    /// Subtext object model
    var editorText = ""
    /// Are all changes to editor saved?
    var editorSaveState = SaveState.saved
    /// Editor selection corresponds with `editorAttributedText`
    var editorSelection = NSMakeRange(0, 0)
    /// Slashlink currently being written (if any)
    var editorSelectedSlashlink: Subtext.Slashlink? = nil

    /// Backlinks to the currently active entry
    var backlinks: [EntryStub] = []

    /// Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var linkSearchText = ""
    var linkSuggestions: [LinkSuggestion] = []

    /// Determine if the interface is ready for user interaction,
    /// even if all of the data isn't refreshed yet.
    /// This is the point at which the main interface is ready to be shown.
    var isReadyForInteraction: Bool {
        self.databaseState == .ready
    }

    /// Given a particular entry value, does the editor's state
    /// currently match it, such that we could say the editor is
    /// displaying that entry?
    func isEditorMatchingEntry(_ entry: SubtextFile) -> Bool {
        self.slug == entry.slug && self.editorText == entry.dom.base
    }

    /// Get a Subtext file snapshot for the current editor state
    func snapshotEditorAsEntry() -> SubtextFile? {
        guard let slug = self.slug else {
            return nil
        }
        return SubtextFile(slug: slug, content: self.editorText)
    }
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
extension AppModel {
    static let logger = Logger.store

    /// Call through to main update function and log updates
    /// when `state.config.debug` is `true`.
    static func updateAndLog(
        state: AppModel,
        environment: AppEnvironment,
        action: AppAction
    ) -> Update<AppModel, AppAction> {
        if state.config.debug {
            logger.debug("Action: \(String(describing: action))")
        }
        // Generate next state and effect
        let next = update(
            state: state,
            environment: environment,
            action: action
        )
        if state.config.debug {
            logger.debug("State: \(String(describing: next.state))")
        }
        return next
    }

    /// Main update function
    static func update(
        state: AppModel,
        environment: AppEnvironment,
        action: AppAction
    ) -> Update<AppModel, AppAction> {
        switch action {
        case .noop:
            return Update(state: state)
        case let .scenePhaseChange(phase):
            return scenePhaseChange(
                state: state,
                phase: phase,
                environment: environment
            )
        case .appear:
            return appear(state: state, environment: environment)
        case let .changeKeyboardState(keyboard):
            return changeKeyboardState(state: state, keyboard: keyboard)
        case .poll:
            // Auto-save entry currently being edited, if any.
            let fx: Fx<AppAction> = Just(
                AppAction.save
            )
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        case let .openURL(url):
            UIApplication.shared.open(url)
            return Update(state: state)
        case let .openEditorURL(url, range):
            return openEditorURL(state: state, url: url, range: range)
        case let .setFocus(focus):
            return setFocus(
                state: state,
                focus: focus
            )
        case .resignFocus(let focus):
            return resignFocus(
                state: state,
                focus: focus
            )
        case .readyDatabase:
            return readyDatabase(state: state, environment: environment)
        case let .migrateDatabaseSuccess(success):
            return migrateDatabaseSuccess(
                state: state,
                environment: environment,
                success: success
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
            var model = state
            model.databaseState = .broken
            return Update(state: model)
        case .sync:
            return sync(
                state: state,
                environment: environment
            )
        case let .syncSuccess(changes):
            return syncSuccess(
                state: state,
                environment: environment,
                changes: changes
            )
        case let .syncFailure(message):
            environment.logger.warning(
                "File sync failed: \(message)"
            )
            return Update(state: state)
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
        case let .showRenameSheet(slug):
            return showRenameSheet(
                state: state,
                environment: environment,
                slug: slug
            )
        case .hideRenameSheet:
            return hideRenameSheet(
                state: state,
                environment: environment
            )
        case let .setRenameSlugField(text):
            return setRenameSlugField(
                state: state,
                environment: environment,
                text: text
            )
        case let .setRenameSuggestions(suggestions):
            return setRenameSuggestions(state: state, suggestions: suggestions)
        case let .renameSuggestionsFailure(error):
            return renameSuggestionsError(
                state: state,
                environment: environment,
                error: error
            )
        case let .renameEntry(from, suggestion):
            return renameEntry(
                state: state,
                environment: environment,
                from: from,
                suggestion: suggestion
            )
        case let .succeedRenameEntry(from, to):
            return succeedRenameEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case let .failRenameEntry(error):
            return failRenameEntry(
                state: state,
                environment: environment,
                error: error
            )
        case .selectDoneEditing:
            return selectDoneEditing(
                state: state,
                environment: environment
            )
        case let .setEditor(text, saveState):
            return setEditor(
                state: state,
                text: text,
                saveState: saveState
            )
        case let .setEditorSelection(range):
            return setEditorSelection(
                state: state,
                environment: environment,
                range: range
            )
        case let .insertEditorText(text, range):
            return insertEditorText(
                state: state,
                text: text,
                range: range,
                environment: environment
            )
        case let .showDetail(isShowing):
            return showDetail(
                state: state,
                isShowing: isShowing,
                environment: environment
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
            model.focus = .search
            return Update(state: model)
                .animation(.easeOutCubic(duration: Duration.keyboard))
        case .hideSearch:
            var model = state
            model.isSearchShowing = false
            model.searchText = ""
            model.focus = nil
            return Update(state: model)
                .animation(.easeOutCubic(duration: Duration.keyboard))
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
        case let .requestDetail(slug, fallback):
            return requestDetail(
                state: state,
                environment: environment,
                slug: slug,
                fallback: fallback
            )
        case let .updateDetail(results):
            return updateDetail(
                state: state,
                environment: environment,
                detail: results
            )
        case let .failDetail(message):
            environment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return Update(state: state)
        case .failRandomDetail(let error):
            return warn(
                state: state,
                environment: environment,
                error: error
            )
        case let .setLinkSheetPresented(isPresented):
            var model = state
            model.focus = isPresented ? .linkSearch : .editor
            model.isLinkSheetPresented = isPresented
            return Update(state: model)
        case let .setLinkSearch(text):
            return setLinkSearch(
                state: state,
                environment: environment,
                text: text
            )
        case let .selectLinkSuggestion(suggestion):
            return selectLinkSuggestion(state: state, suggestion: suggestion)
        case let .setLinkSuggestions(suggestions):
            var model = state
            model.linkSuggestions = suggestions
            return Update(state: model)
        case let .linkSuggestionsFailure(message):
            environment.logger.debug(
                "Link suggest failed: \(message)"
            )
            return Update(state: state)
        case .save:
            return save(
                state: state,
                environment: environment
            )
        case let .succeedSave(entry):
            return succeedSave(
                state: state,
                environment: environment,
                entry: entry
            )
        case let .failSave(slug, message):
            return failSave(
                state: state,
                environment: environment,
                slug: slug,
                message: message
            )
        }
    }

    static func warn(
        state: AppModel,
        environment: AppEnvironment,
        error: Error
    ) -> Update<AppModel, AppAction> {
        environment.logger.warning("\(error.localizedDescription)")
        return Update(state: state)
    }

    /// Set all editor properties to initial values
    static func resetEditor(state: AppModel) -> AppModel {
        var model = state
        model.slug = nil
        model.isDetailLoading = true
        model.editorText = ""
        model.editorSaveState = .saved
        model.editorSelection = NSMakeRange(0, 0)
        model.editorSelectedSlashlink = nil
        model.focus = nil
        return model
    }

    /// Set the contents of the editor.
    ///
    /// if `isSaved` is `false`, the editor state will be flagged as unsaved,
    /// allowing other processes to save it to disk later.
    /// When setting a `dom` that represents the current saved-to-disk state
    /// mark `isSaved` true.
    ///
    /// - Parameters:
    ///   - state: the state of the app
    ///   - dom: the Subtext DOM that should be rendered and set
    ///   - isSaved: is this text state saved already?
    static func setEditor(
        state: AppModel,
        text: String,
        saveState: SaveState = .modified
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.editorText = text
        // Mark save state
        model.editorSaveState = saveState
        let dom = Subtext(markup: text)
        let slashlink = dom.slashlinkFor(range: state.editorSelection)
        model.editorSelectedSlashlink = slashlink

        // Find out if our selection touches a slashlink.
        // If it does, search for links.
        let fx: Fx<AppAction> = slashlink.mapOr(
            { slashlink in
                Just(
                    AppAction.setLinkSearch(slashlink.description)
                )
                .eraseToAnyPublisher()
            },
            default: Empty().eraseToAnyPublisher()
        )
        return Update(state: model, fx: fx)
    }

    /// Set editor selection.
    static func setEditorSelection(
        state: AppModel,
        environment: AppEnvironment,
        range nsRange: NSRange
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.editorSelection = nsRange
        let dom = Subtext(markup: model.editorText)
        let slashlink = dom.slashlinkFor(
            range: model.editorSelection
        )
        model.editorSelectedSlashlink = slashlink

        let fx: Fx<AppAction> = slashlink.mapOr(
            { slashlink in
                Just(AppAction.setLinkSearch(slashlink.description))
                    .eraseToAnyPublisher()
            },
            default: Just(AppAction.setLinkSearch(""))
                .eraseToAnyPublisher()
        )

        return Update(state: model, fx: fx)
    }

    /// Set text cursor at end of editor
    static func setEditorSelectionEnd(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        let range = NSRange(
            state.editorText.endIndex...,
            in: state.editorText
        )

        return setEditorSelection(
            state: state,
            environment: environment,
            range: range
        )
    }

    static func insertEditorText(
        state: AppModel,
        text: String,
        range nsRange: NSRange,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        guard let range = Range(nsRange, in: state.editorText) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        // Replace selected range with committed link search text.
        let markup = state.editorText.replacingCharacters(
            in: range,
            with: text
        )

        // Find new cursor position
        guard let cursor = markup.index(
            range.lowerBound,
            offsetBy: text.count,
            limitedBy: markup.endIndex
        ) else {
            environment.logger.log(
                "Could not find new cursor position. Aborting text insert."
            )
            return Update(state: state)
        }

        // Set editor dom and editor selection immediately in same
        // Update.
        return setEditor(
            state: state,
            text: markup,
            saveState: .modified
        )
        .pipe({ state in
            setEditorSelection(
                state: state,
                environment: environment,
                range: NSRange(cursor..<cursor, in: markup)
            )
        })
    }

    /// Toggle detail view showing or hiding
    static func showDetail(
        state: AppModel,
        isShowing: Bool,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        // Save any entry that is currently active before we blow it away
        return save(
            state: state,
            environment: environment
        )
        .pipe({ state in
            var model = state
            model.isDetailShowing = isShowing
            if isShowing == false {
                model.focus = nil
            }
            return Update(state: model)
        })
    }

    /// Change state of keyboard
    /// Actions come from `KeyboardService`
    static func changeKeyboardState(
        state: AppModel,
        keyboard: KeyboardState
    ) -> Update<AppModel, AppAction> {
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

    /// Handle scene phase change
    static func scenePhaseChange(
        state: AppModel,
        phase: ScenePhase,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        switch phase {
        case .active:
            let fx: Fx<AppAction> = Just(
                AppAction.readyDatabase
            )
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        default:
            return Update(state: state)
        }
    }

    static func appear(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        environment.logger.debug(
            "Documents: \(environment.documentURL)"
        )

        let countFx: Fx<AppAction> = Just(AppAction.countEntries)
            .eraseToAnyPublisher()

        let pollFx: Fx<AppAction> = AppEnvironment.poll(
            every: state.config.pollingInterval
        )
        .map({ date in
            AppAction.poll(date)
        })
        .eraseToAnyPublisher()

        // Subscribe to keyboard events
        let fx: Fx<AppAction> = environment
            .keyboard.state
            .map({ value in
                AppAction.changeKeyboardState(value)
            })
            .merge(
                with: pollFx,
                countFx
            )
            .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    static func openEditorURL(
        state: AppModel,
        url: URL,
        range: NSRange
    ) -> Update<AppModel, AppAction> {
        // Don't follow links while editing.
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
        guard state.focus != .editor else {
            return Update(state: state)
        }

        // Follow ordinary links when not in edit mode
        guard Slashlink.isSlashlinkURL(url) else {
            UIApplication.shared.open(url)
            return Update(state: state)
        }

        let slug = Slashlink.slashlinkURLToSlug(url)
        // If this is a Subtext URL, then commit a search for the
        // corresponding query
        let fx: Fx<AppAction> = Just(
            AppAction.requestDetail(
                slug: slug,
                fallback: slug.mapOr(
                    { slug in slug.toSentence() },
                    default: ""
                )
            )
        )
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Set focus state.
    /// Note if you want to resign focus, prefer using `resignFocus`.
    static func setFocus(
        state: AppModel,
        focus: AppModel.Focus?
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.focus = focus
        return Update(state: model).animation(.default)
    }

    /// Resign focus if you have it.
    /// Otherwise leave focus untouched.
    static func resignFocus(
        state: AppModel,
        focus: AppModel.Focus
    ) -> Update<AppModel, AppAction> {
        var model  = state
        if model.focus == focus {
            model.focus = nil
        }
        return Update(state: model).animation(.default)
    }

    /// Make database ready.
    /// This will kick off a migration IF a successful migration
    /// has not already occurred.
    static func readyDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        switch state.databaseState {
        case .initial:
            environment.logger.log("Readying database")
            let fx: Fx<AppAction> = environment.database
                .migrate()
                .map({ success in
                    AppAction.migrateDatabaseSuccess(success)
                })
                .catch({ _ in
                    Just(AppAction.rebuildDatabase)
                })
                .eraseToAnyPublisher()
            var model = state
            model.databaseState = .migrating
            return Update(state: model, fx: fx)
        case .migrating:
            environment.logger.log(
                "Database already migrating. Doing nothing."
            )
            return Update(state: state)
        case .broken:
            environment.logger.warning(
                "Database broken. Doing nothing."
            )
            return Update(state: state)
        case .ready:
            environment.logger.log("Database ready. Syncing.")
            let fx: Fx<AppAction> = Just(
                AppAction.sync
            )
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        }
    }

    static func migrateDatabaseSuccess(
        state: AppModel,
        environment: AppEnvironment,
        success: SQLite3Migrations.MigrationSuccess
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.databaseState = .ready
        let fx: Fx<AppAction> = Just(
            AppAction.sync
        )
        // Refresh all from database immediately while sync happens
        // in background.
        .merge(with: Just(.refreshAll))
        .eraseToAnyPublisher()
        if success.from != success.to {
            environment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        return Update(state: model, fx: fx)
    }

    static func rebuildDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        environment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        let fx: Fx<AppAction> = environment.database
            .delete()
            .flatMap({ _ in
                environment.database.migrate()
            })
            .map({ success in
                AppAction.migrateDatabaseSuccess(success)
            })
            .catch({ error in
                Just(AppAction.rebuildDatabaseFailure(
                    error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Start file sync
    static func sync(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        environment.logger.log("File sync started")
        let fx: Fx<AppAction> = environment.database
            .syncDatabase()
            .map({ changes in
                AppAction.syncSuccess(changes)
            })
            .catch({ error in
                Just(AppAction.syncFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle successful sync
    static func syncSuccess(
        state: AppModel,
        environment: AppEnvironment,
        changes: [FileSync.Change]
    ) -> Update<AppModel, AppAction> {
        environment.logger.debug(
            "File sync finished: \(changes)"
        )

        // Refresh lists after completing sync.
        // This ensures that files which were deleted outside the app
        // are removed from lists once sync is complete.
        let fx: Fx<AppAction> = Just(
            AppAction.refreshAll
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Refresh all lists in the app from database
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshAll(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        return listRecent(state: state, environment: environment)
            .pipe({ state in
                setSearch(
                    state: state,
                    environment: environment,
                    text: state.searchText
                )
            })
            .pipe({ state in
                setLinkSearch(
                    state: state,
                    environment: environment,
                    text: state.linkSearchText
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
        state: AppModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<AppModel, AppAction> {
        let fx: Fx<AppAction> = environment.database
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
        return Update(state: state, fx: fx)
    }

    /// Handle success case for search history item creation
    static func createSearchHistoryItemSuccess(
        state: AppModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<AppModel, AppAction> {
        environment.logger.log(
            "Created search history entry: \(query)"
        )
        return Update(state: state)
    }

    /// Handle failure case for search history item creation
    static func createSearchHistoryItemFailure(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel, AppAction> {
        environment.logger.warning(
            "Failed to create search history entry: \(error)"
        )
        return Update(state: state)
    }

    /// Read entry count from db
    static func countEntries(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        let fx: Fx<AppAction> = environment.database.countEntries()
            .map({ count in
                AppAction.setEntryCount(count)
            })
            .catch({ error in
                Just(AppAction.failEntryCount(error))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Set entry count
    static func setEntryCount(
        state: AppModel,
        environment: AppEnvironment,
        count: Int
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.entryCount = count
        return Update(state: model)
    }

    static func listRecent(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        let fx: Fx<AppAction> = environment.database
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
        return Update(state: state, fx: fx)
    }

    /// Delete entry with `slug`
    static func deleteEntry(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<AppModel, AppAction> {
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

        let fx: Fx<AppAction> = environment.database
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
        return Update(state: model, fx: fx)
    }

    /// Handle completion of entry delete
    static func deleteEntrySuccess(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<AppModel, AppAction> {
        environment.logger.log("Deleted entry: \(slug)")
        //  Refresh lists in search fields after delete.
        //  This ensures they don't show the deleted entry.
        let fx: Fx<AppAction> = Just(AppAction.refreshAll)
            .eraseToAnyPublisher()

        var model = state
        // If we just deleted the entry currently being edited,
        // reset the editor to initial state (nothing is being edited).
        if state.slug == slug {
            model = resetEditor(state: model)
            model.isDetailShowing = false
        }

        return Update(
            state: model,
            fx: fx
        )
    }

    /// Show rename sheet.
    /// Do rename-flow-related setup.
    static func showRenameSheet(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug?
    ) -> Update<AppModel, AppAction> {
        guard let slug = slug else {
            environment.logger.warning(
                "Rename sheet invoked with nil slug"
            )
            return Update(state: state)
        }

        var model = state
        model.isRenameSheetShowing = true
        model.slugToRename = slug

        return Update(state: model)
            //  Save entry in preperation for any merge/move.
            .pipe({ state in
                save(state: state, environment: environment)
            })
            //  Set rename slug field text
            .pipe({ state in
                setRenameSlugField(
                    state: state,
                    environment: environment,
                    text: slug.description
                )
            })
            //  Set focus on rename field
            .pipe({ state in
                setFocus(state: state, focus: .rename)
            })
    }

    /// Hide rename sheet.
    /// Do rename-flow-related teardown.
    static func hideRenameSheet(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.isRenameSheetShowing = false
        model.slugToRename = nil

        return Update(state: model)
            .pipe({ state in
                setRenameSlugField(
                    state: state,
                    environment: environment,
                    text: ""
                )
            })
            .pipe({ state in
                resignFocus(state: state, focus: .rename)
            })
    }

    /// Set text of slug field
    static func setRenameSlugField(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel, AppAction> {
        var model = state
        let sluglike = Slug.format(text).unwrap(or: "")
        model.renameSlugField = sluglike
        let fx: Fx<AppAction> = environment.database
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
        return Update(state: model, fx: fx)
    }

    /// Set rename suggestions
    static func setRenameSuggestions(
        state: AppModel,
        suggestions: [RenameSuggestion]
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.renameSuggestions = suggestions
        return Update(state: model)
    }

    /// Handle rename suggestions error.
    /// This case can happen e.g. if the database fails to respond.
    static func renameSuggestionsError(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel, AppAction> {
        environment.logger.warning(
            "Failed to read suggestions from database: \(error)"
        )
        return Update(state: state)
    }

    /// Rename an entry (change its slug).
    /// If `next` does not already exist, this will change the slug
    /// and move the file.
    /// If next exists, this will merge documents.
    static func renameEntry(
        state: AppModel,
        environment: AppEnvironment,
        from: Slug?,
        suggestion: RenameSuggestion
    ) -> Update<AppModel, AppAction> {
        guard let from = from else {
            let fx: Fx<AppAction> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            environment.logger.warning(
                "Rename invoked without original slug. Doing nothing."
            )
            return Update(state: state, fx: fx)
        }

        let to: Slug = Func.pipe(suggestion) { suggestion in
            switch suggestion {
            case .rename(let entryLink):
                return entryLink.slug
            case .merge(let entryLink):
                return entryLink.slug
            }
        }

        guard from != to else {
            let fx: Fx<AppAction> = Just(.hideRenameSheet)
                .eraseToAnyPublisher()
            environment.logger.log(
                "Rename invoked with same name. Doing nothing."
            )
            return Update(state: state, fx: fx)
                .animation(.easeOutCubic(duration: Duration.keyboard))
        }

        let fx: Fx<AppAction> = environment.database
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
        return Update(state: state, fx: fx)
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Rename success lifecycle handler.
    /// Updates UI in response.
    static func succeedRenameEntry(
        state: AppModel,
        environment: AppEnvironment,
        from: Slug,
        to: Slug
    ) -> Update<AppModel, AppAction> {
        environment.logger.log("Renamed entry from \(from) to \(to)")
        let fx: Fx<AppAction> = Just(
            AppAction.requestDetail(slug: to, fallback: "")
        )
        .merge(with: Just(AppAction.refreshAll))
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Rename failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failRenameEntry(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel, AppAction> {
        environment.logger.warning(
            "Failed to rename entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Unfocus editor and save current state
    static func selectDoneEditing(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        return save(
            state: state,
            environment: environment
        )
        .pipe({ state in
            resignFocus(state: state, focus: .editor)
        })
    }

    /// Set search text for main search input
    static func setSearch(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.searchText = text
        let fx: Fx<AppAction> = environment.database
            .searchSuggestions(
                query: text,
                isJournalSuggestionEnabled:
                    state.config.journalSuggestionEnabled,
                isScratchSuggestionEnabled:
                    state.config.scratchSuggestionEnabled,
                isRandomSuggestionEnabled:
                    state.config.randomSuggestionEnabled
            )
            .map({ suggestions in
                AppAction.setSuggestions(suggestions)
            })
            .catch({ error in
                Just(.suggestionsFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }

    /// Handle user select search suggestion
    static func selectSuggestion(
        state: AppModel,
        environment: AppEnvironment,
        suggestion: Suggestion
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.isSearchShowing = false

        switch suggestion {
        case .entry(let entryLink):
            return requestDetail(
                state: model,
                environment: environment,
                slug: entryLink.slug,
                fallback: entryLink.title
            )
            .animation(.easeOutCubic(duration: Duration.keyboard))
        case .search(let entryLink):
            return requestDetail(
                state: model,
                environment: environment,
                slug: entryLink.slug,
                fallback: entryLink.title
            )
            .animation(.easeOutCubic(duration: Duration.keyboard))
        case .journal(let entryLink):
            return requestTemplateDetail(
                state: model,
                environment: environment,
                slug: entryLink.slug,
                template: state.config.journalTemplate
            )
            .animation(.easeOutCubic(duration: Duration.keyboard))
        case .scratch(let entryLink):
            return requestDetail(
                state: model,
                environment: environment,
                slug: entryLink.slug,
                fallback: entryLink.title
            )
            .animation(.easeOutCubic(duration: Duration.keyboard))
        case .random:
            return requestRandomDetail(
                state: model,
                environment: environment
            )
            .animation(.easeOutCubic(duration: Duration.keyboard))
        }
    }

    /// Request that entry detail view be shown
    static func requestDetail(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String
    ) -> Update<AppModel, AppAction> {
        // If nil slug was requested, do nothing
        guard let slug = slug else {
            environment.logger.log(
                "Detail requested for nil slug. Doing nothing."
            )
            return Update(state: state)
        }
        // Save current state before we blow it away
        return save(
            state: state,
            environment: environment
        )
        .pipe({ state in
            var model = state
            model.isDetailLoading = true
            model.searchText = ""
            model.isSearchShowing = false
            model.isDetailShowing = true
            let fx: Fx<AppAction> = environment.database
                .readEntryDetail(
                    slug: slug,
                    // Trim whitespace and add blank line to end of string
                    // This gives us a good starting point to start
                    // editing.
                    fallback: fallback.formattingBlankLineEnding()
                )
                .map({ detail in
                    AppAction.updateDetail(detail)
                })
                .catch({ error in
                    Just(AppAction.failDetail(error.localizedDescription))
                })
                .merge(
                    with: Just(AppAction.setSearch("")),
                    Just(AppAction.createSearchHistoryItem(fallback))
                )
                .eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        })
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Request detail, using contents of template file as fallback content
    static func requestTemplateDetail(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug,
        template: Slug
    ) -> Update<AppModel, AppAction> {
        /// Get template contents
        let fallback = environment.database
            .readEntry(slug: template)
            .map({ entry in entry.content })
            .unwrap(or: "")
        return requestDetail(
            state: state,
            environment: environment,
            slug: slug,
            fallback: fallback
        )
    }

    /// Request detail for a random entry
    static func requestRandomDetail(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        let fx: Fx<AppAction> = environment.database.readRandomEntrySlug()
            .map({ slug in
                AppAction.requestDetail(
                    slug: slug,
                    fallback: slug.toSentence()
                )
            })
            .catch({ error in
                Just(AppAction.failRandomDetail(error))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Update entry detail.
    /// This case gets hit after requesting detail for an entry.
    static func updateDetail(
        state: AppModel,
        environment: AppEnvironment,
        detail: EntryDetail
    ) -> Update<AppModel, AppAction> {
        var model = resetEditor(state: state)
        model.isDetailLoading = false
        model.slug = detail.slug
        model.backlinks = detail.backlinks

        let update = setEditor(
            state: model,
            text: detail.entry.value.dom.base,
            saveState: detail.entry.state
        )
        .pipe({ state in
            save(
                state: state,
                environment: environment
            )
        })

        // If detail is not a just-created draft, return update
        guard detail.entry.state == .draft else {
            return update
        }

        // Otherwise, set editor selection and focus to end of document.
        // When you've just created a new note, chances are you want to
        // edit it, not browse it.
        // We focus the editor and place the cursor at the end so you can just
        // start typing
        return update
            .pipe({ state in
                setEditorSelectionEnd(
                    state: state,
                    environment: environment
                )
            })
            .pipe({ state in
                setFocus(state: state, focus: .editor)
            })
    }

    static func setLinkSearch(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel, AppAction> {
        var model = state
        let sluglike = Slug.format(text).unwrap(or: "")
        model.linkSearchText = sluglike

        // Omit current slug from results
        let omitting = state.slug.mapOr(
            { slug in Set([slug]) },
            default: Set()
        )

        // Get fallback link suggestions
        let fallback = environment.database.readDefaultLinkSuggestions(
            config: model.config
        )

        // Search link suggestions
        let fx: Fx<AppAction> = environment.database
            .searchLinkSuggestions(
                query: text,
                omitting: omitting,
                fallback: fallback
            )
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

        return Update(state: model, fx: fx)
    }

    static func selectLinkSuggestion(
        state: AppModel,
        suggestion: LinkSuggestion
    ) -> Update<AppModel, AppAction> {
        let slug: Slug = Func.pipe(suggestion, { suggestion in
            switch suggestion {
            case .entry(let entryLink):
                return entryLink.slug
            case .new(let entryLink):
                return entryLink.slug
            }
        })

        var range = state.editorSelection
        // If there is a selected slashlink, use that range
        // instead of selection
        if let slashlink = state.editorSelectedSlashlink
        {
            range = NSRange(
                slashlink.span.range,
                in: state.editorText
            )
        }

        let fx: Fx<AppAction> = Just(
            AppAction.setLinkSheetPresented(false)
        )
        .merge(
            with: Just(
                AppAction.insertEditorText(
                    text: "\(slug.toSlashlink()) ",
                    range: range
                )
            )
        )
        .eraseToAnyPublisher()

        var model = state
        model.linkSearchText = ""

        return Update(state: model, fx: fx)
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Save snapshot of entry
    static func save(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        // If editor dom is already saved, noop
        guard state.editorSaveState != .saved else {
            return Update(state: state)
        }

        // If there is no entry currently being edited, noop.
        guard let entry = state.snapshotEditorAsEntry() else {
            let saveState = String(reflecting: state.editorSaveState)
            environment.logger.warning(
                "Entry save state is marked \(saveState) but no entry could be derived for state"
            )
            return Update(state: state)
        }

        var model = state
        // Mark saving in-progress
        model.editorSaveState = .saving

        let fx: Fx<AppAction> = environment.database
            .writeEntry(
                entry: entry
            )
            .map({ _ in
                AppAction.succeedSave(entry)
            })
            .catch({ error in
                Just(
                    AppAction.failSave(
                        slug: entry.slug,
                        message: error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }

    /// Log save success and perform refresh of various lists.
    static func succeedSave(
        state: AppModel,
        environment: AppEnvironment,
        entry: SubtextFile
    ) -> Update<AppModel, AppAction> {
        environment.logger.debug(
            "Saved entry: \(entry.slug)"
        )
        let fx = Just(AppAction.refreshAll)
            .eraseToAnyPublisher()

        var model = state

        // If editor state is still the state we invoked save with,
        // then mark the current editor state as "saved".
        // We check before setting in case changes happened between the
        // time we invoked save and the time it completed.
        // If changes did happen in that time, we want to mark the current
        // state modified, giving other processes a chance to save the
        // new changes.
        // 2022-02-09 Gordon Brander
        if
            model.editorSaveState == .saving &&
            model.isEditorMatchingEntry(entry)
        {
            model.editorSaveState = .saved
        }

        return Update(state: model, fx: fx)
    }

    static func failSave(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug,
        message: String
    ) -> Update<AppModel, AppAction> {
        //  TODO: show user a "try again" banner
        environment.logger.warning(
            "Save failed for entry (\(slug)) with error: \(message)"
        )
        // Mark modified, since we failed to save
        var model = state
        model.editorSaveState = .modified
        return Update(state: model)
    }
}

//  MARK: Environment
/// A place for constants and services
struct AppEnvironment {
    var documentURL: URL
    var applicationSupportURL: URL

    var logger: Logger
    var keyboard: KeyboardService
    var database: DatabaseService

    /// Create a long polling publisher that never completes
    static func poll(every interval: Double) -> AnyPublisher<Date, Never> {
        Timer.publish(
            every: interval,
            on: .main,
            in: .default
        )
        .autoconnect()
        .eraseToAnyPublisher()
    }

    init() {
        self.documentURL = FileManager.default.urls(
            for: .documentDirectory,
               in: .userDomainMask
        ).first!

        self.applicationSupportURL = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        self.logger = Logger.main

        self.database = DatabaseService(
            documentURL: self.documentURL,
            databaseURL: self.applicationSupportURL
                .appendingPathComponent("database.sqlite"),
            migrations: Self.migrations
        )

        self.keyboard = KeyboardService()
    }
}

//  MARK: Migrations
extension AppEnvironment {
    static let migrations = SQLite3Migrations([
        SQLite3Migrations.Migration(
            date: "2021-11-04T12:00:00",
            sql: """
            CREATE TABLE search_history (
                id TEXT PRIMARY KEY,
                query TEXT NOT NULL,
                created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE entry (
              slug TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL,
              modified TEXT NOT NULL,
              size INTEGER NOT NULL
            );

            CREATE VIRTUAL TABLE entry_search USING fts5(
              slug,
              title,
              body,
              modified UNINDEXED,
              size UNINDEXED,
              content="entry",
              tokenize="porter"
            );

            /*
            Create triggers to keep fts5 virtual table in sync with content table.

            Note: SQLite documentation notes that you want to modify the fts table *before*
            the external content table, hence the BEFORE commands.

            These triggers are adapted from examples in the docs:
            https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
            */
            CREATE TRIGGER entry_search_before_update BEFORE UPDATE ON entry BEGIN
              DELETE FROM entry_search WHERE rowid=old.rowid;
            END;

            CREATE TRIGGER entry_search_before_delete BEFORE DELETE ON entry BEGIN
              DELETE FROM entry_search WHERE rowid=old.rowid;
            END;

            CREATE TRIGGER entry_search_after_update AFTER UPDATE ON entry BEGIN
              INSERT INTO entry_search
                (
                  rowid,
                  slug,
                  title,
                  body,
                  modified,
                  size
                )
              VALUES
                (
                  new.rowid,
                  new.slug,
                  new.title,
                  new.body,
                  new.modified,
                  new.size
                );
            END;

            CREATE TRIGGER entry_search_after_insert AFTER INSERT ON entry BEGIN
              INSERT INTO entry_search
                (
                  rowid,
                  slug,
                  title,
                  body,
                  modified,
                  size
                )
              VALUES
                (
                  new.rowid,
                  new.slug,
                  new.title,
                  new.body,
                  new.modified,
                  new.size
                );
            END;
            """
        )!
    ])!
}
