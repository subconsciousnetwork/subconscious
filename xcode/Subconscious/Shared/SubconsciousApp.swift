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
typealias AppStore = Store<AppModel, AppAction, AppEnvironment>

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

    /// Set focus from a particular field
    case setFocus(
        focus: AppModel.Focus?,
        field: AppModel.Focus
    )

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
    /// Hit submit ("go") while focused on search field
    case submitSearch(String)

    // Search suggestions
    /// Submit search suggestion
    case selectSuggestion(Suggestion)
    case setSuggestions([Suggestion])
    case suggestionsFailure(String)

    // Detail
    case requestDetail(
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    )
    /// request detail for slug, using template file as a fallback
    case requestTemplateDetail(
        slug: Slug,
        template: Slug,
        autofocus: Bool
    )
    case requestRandomDetail(autofocus: Bool)
    case updateDetail(detail: EntryDetail, autofocus: Bool)
    case failDetail(String)
    case failRandomDetail(Error)
    case showDetail(Bool)

    // Editor
    /// Invokes save and blurs editor
    case selectDoneEditing
    /// Update editor dom and mark if this state is saved or not
    case setEditor(text: String, saveState: SaveState)
    /// Set selected range in editor
    case setEditorSelection(NSRange)
    /// Insert text into editor, replacing range
    case insertEditorText(
        text: String,
        range: NSRange
    )
    /// Insert wikilink markup, wrapping range
    case insertEditorWikilinkAtSelection
    case insertEditorBoldAtSelection
    case insertEditorItalicAtSelection
    case insertEditorCodeAtSelection

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

    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
    }
}

extension AppAction {
    /// Generates a short (approximately 1 line) loggable string for action.
    func toLogString() -> String {
        switch self {
        case .setRecent(let items):
            return "setRecent(...) (\(items.count) items)"
        case .setSuggestions(let items):
            return "setSuggestions(...) (\(items.count) items)"
        case .setLinkSuggestions(let items):
            return "setLinkSuggestions(...) (\(items.count) items)"
        case .setRenameSuggestions(let items):
            return "setRenameSuggestions(...) (\(items.count) items)"
        case .updateDetail(let detail, _):
            return "updateDetail(\(detail.slug)) (saved state: \(detail.saveState))"
        default:
            return String(describing: self)
        }
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

    /// Main search suggestions
    var suggestions: [Suggestion] = []

    // Editor
    var editor = Editor()

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
        (
            self.editor.slug == entry.slug &&
            self.editor.text == entry.envelope.body.base
        )
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
    /// Call through to main update function and log updates
    /// when `state.config.debug` is `true`.
    static func updateAndLog(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        Logger.action.debug("\(action.toLogString())")
        // Generate next state and effect
        let next = update(
            state: state,
            action: action,
            environment: environment
        )
        if state.config.debug {
            Logger.state.debug("\(String(describing: next.state))")
        }
        return next
    }

    /// Main update function
    static func update(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
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
        case let .setFocus(focus, field):
            return setFocus(
                state: state,
                environment: environment,
                focus: focus,
                field: field
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
                environment: environment,
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
                environment: environment,
                text: text,
                range: range
            )
        case .insertEditorWikilinkAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Wikilink(text: text) }
            )
        case .insertEditorBoldAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Bold(text: text) }
            )
        case .insertEditorItalicAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Italic(text: text) }
            )
        case .insertEditorCodeAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.editor.selection,
                with: { text in Markup.Code(text: text) }
            )
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
            return Update(state: model)
                .pipe({ state in
                    setFocus(
                        state: state,
                        environment: environment,
                        focus: .search,
                        field: .search
                    )
                })
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
        case let .requestDetail(slug, fallback, autofocus):
            return requestDetail(
                state: state,
                environment: environment,
                slug: slug,
                fallback: fallback,
                autofocus: autofocus
            )
        case let .requestTemplateDetail(slug, template, autofocus):
            return requestTemplateDetail(
                state: state,
                environment: environment,
                slug: slug,
                template: template,
                autofocus: autofocus
            )
        case let .requestRandomDetail(autofocus):
            return requestRandomDetail(
                state: state,
                environment: environment,
                autofocus: autofocus
            )
        case let .updateDetail(results, autofocus):
            return updateDetail(
                state: state,
                environment: environment,
                detail: results,
                autofocus: autofocus
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
            return setLinkSheetPresented(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case let .setLinkSearch(text):
            return setLinkSearch(
                state: state,
                environment: environment,
                text: text
            )
        case let .selectLinkSuggestion(suggestion):
            return selectLinkSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
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
        model.editor = Editor()
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
        environment: AppEnvironment,
        text: String,
        saveState: SaveState = .modified
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.editor.text = text
        // Mark save state
        model.editor.saveState = saveState
        let dom = Subtext.parse(markup: text)
        let link = dom.entryLinkFor(range: state.editor.selection)
        model.editor.selectedEntryLinkMarkup = link

        let linkSearchText = link?.toTitle() ?? ""

        return Update(state: model)
            .pipe({ state in
                setLinkSearch(
                    state: state,
                    environment: environment,
                    text: linkSearchText
                )
            })
    }

    /// Set editor selection.
    static func setEditorSelection(
        state: AppModel,
        environment: AppEnvironment,
        range nsRange: NSRange
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.editor.selection = nsRange
        let dom = Subtext.parse(markup: model.editor.text)
        let link = dom.entryLinkFor(
            range: model.editor.selection
        )
        model.editor.selectedEntryLinkMarkup = link

        let linkSearchText = link?.toTitle() ?? ""

        return Update(state: model)
            .pipe({ state in
                setLinkSearch(
                    state: state,
                    environment: environment,
                    text: linkSearchText
                )
            })
    }

    /// Set text cursor at end of editor
    static func setEditorSelectionEnd(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        let range = NSRange(
            state.editor.text.endIndex...,
            in: state.editor.text
        )

        return setEditorSelection(
            state: state,
            environment: environment,
            range: range
        )
    }

    /// Insert text in editor at range
    static func insertEditorText(
        state: AppModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<AppModel, AppAction> {
        guard let range = Range(nsRange, in: state.editor.text) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        // Replace selected range with committed link search text.
        let markup = state.editor.text.replacingCharacters(
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
            environment: environment,
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

    /// Insert wikilink markup into editor, begining at previous range
    /// and wrapping the contents of previous range
    static func insertTaggedMarkup<T>(
        state: AppModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        with withMarkup: (String) -> T
    ) -> Update<AppModel, AppAction>
    where T: TaggedMarkup
    {
        guard let range = Range(nsRange, in: state.editor.text) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        let selectedText = String(state.editor.text[range])
        let markup = withMarkup(selectedText)

        // Replace selected range with committed link search text.
        let editorText = state.editor.text.replacingCharacters(
            in: range,
            with: String(describing: markup)
        )

        // Find new cursor position
        guard let cursor = editorText.index(
            range.lowerBound,
            offsetBy: markup.markupWithoutClosingTag.count,
            limitedBy: editorText.endIndex
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
            environment: environment,
            text: editorText,
            saveState: .modified
        )
        .pipe({ state in
            setEditorSelection(
                state: state,
                environment: environment,
                range: NSRange(cursor..<cursor, in: editorText)
            )
        })
    }

    /// Toggle detail view showing or hiding
    static func showDetail(
        state: AppModel,
        environment: AppEnvironment,
        isShowing: Bool
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.isDetailShowing = isShowing
        return Update(state: model)
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
        // Follow ordinary links when not in edit mode
        guard SubURL.isSubEntryURL(url) else {
            UIApplication.shared.open(url)
            return Update(state: state)
        }

        let link = EntryLink.decodefromSubEntryURL(url)
        let fx: Fx<AppAction> = Just(
            AppAction.requestDetail(
                slug: link?.slug,
                fallback: link?.title ?? "",
                autofocus: false
            )
        )
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Set focus state.
    static func setFocus(
        state: AppModel,
        environment: AppEnvironment,
        focus: AppModel.Focus?,
        field: AppModel.Focus
    ) -> Update<AppModel, AppAction> {
        // If desired focus is not nil, just set it.
        if focus != nil {
            var model = state
            model.focus = focus
            return Update(state: model).animation(.default)
        }
        // If desired focus is nil, only resign focus if the current focus
        // is on the expected focus field.
        // In general, nil means "relinquish my focus", not
        // "relinquish all focus". If someone else has taken focus in the
        // meantime, we don't want to stomp on them.
        else if focus == nil && state.focus == field {
            var model = state
            model.focus = nil
            return Update(state: model).animation(.default)
        }
        // Otherwise, do nothing.
        else {
            let fieldString = String(describing: field)
            let currentString = String(describing: state.focus)
            environment.logger.debug(
                "setFocus: requested nil focus for field \(fieldString), but focus already changed to \(currentString). Noop."
            )
            return Update(state: state)
        }
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
            .animation(.default)
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
        if state.editor.slug == slug {
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
                setFocus(
                    state: state,
                    environment: environment,
                    focus: .rename,
                    field: .rename
                )
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
                setFocus(
                    state: state,
                    environment: environment,
                    focus: nil,
                    field: .rename
                )
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
            AppAction.requestDetail(
                slug: to,
                fallback: "",
                autofocus: false
            )
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
            setFocus(
                state: state,
                environment: environment,
                focus: nil,
                field: .editor
            )
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

    /// Set search HUD to hidden state
    static func hideSearch(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.isSearchShowing = false
        model.searchText = ""
        return Update(state: model)
            .pipe({ state in
                setFocus(
                    state: state,
                    environment: environment,
                    focus: nil,
                    field: .search
                )
            })
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Submit a search query (typically by hitting "go" on keyboard)
    static func submitSearch(
        state: AppModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<AppModel, AppAction> {
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

        let fx: Fx<AppAction> = Just(
            AppAction.requestDetail(
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
        state: AppModel,
        environment: AppEnvironment,
        suggestion: Suggestion
    ) -> Update<AppModel, AppAction> {
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
            let fx: Fx<AppAction> = Just(
                AppAction.requestDetail(
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
            let fx: Fx<AppAction> = Just(
                AppAction.requestDetail(
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
            let fx: Fx<AppAction> = Just(
                AppAction.requestTemplateDetail(
                    slug: entryLink.slug,
                    template: state.config.journalTemplate,
                    // Autofocus note because we're creating it from scratch
                    autofocus: true
                )
            )
            // Request detail AFTER animaiton completes
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        case .scratch(let entryLink):
            let fx: Fx<AppAction> = Just(
                AppAction.requestDetail(
                    slug: entryLink.slug,
                    fallback: entryLink.title,
                    autofocus: true
                )
            )
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        case .random:
            let fx: Fx<AppAction> = Just(
                AppAction.requestRandomDetail(autofocus: false)
            )
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

            return update.mergeFx(fx)
        }
    }

    /// Factors out the non-get-detail related aspects
    /// of requesting a detail view.
    /// Used by a few request detail implementations.
    private static func prepareRequestDetail(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.editor.isLoading = true

        // Save current state before we blow it away
        return save(
            state: model,
            environment: environment
        )
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Request detail view for entry.
    /// Fall back on string (typically query string) when no detail
    /// exists for this slug yet.
    static func requestDetail(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    ) -> Update<AppModel, AppAction> {
        // If nil slug was requested, do nothing
        guard let slug = slug else {
            environment.logger.log(
                "Detail requested for nil slug. Doing nothing."
            )
            return Update(state: state)
        }

        let fx: Fx<AppAction> = environment.database
            .readEntryDetail(
                slug: slug,
                // Trim whitespace and add blank line to end of string
                // This gives us a good starting point to start
                // editing.
                fallback: fallback.formattingBlankLineEnding()
            )
            .map({ detail in
                AppAction.updateDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(AppAction.failDetail(error.localizedDescription))
            })
            .merge(
                with: Just(AppAction.setSearch("")),
                Just(AppAction.createSearchHistoryItem(fallback))
            )
            .eraseToAnyPublisher()

        return prepareRequestDetail(
            state: state,
            environment: environment,
            slug: slug
        )
        .mergeFx(fx)
    }

    /// Request detail view for entry.
    /// Fall back on contents of template file when no detail
    /// exists for this slug yet.
    static func requestTemplateDetail(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug,
        template: Slug,
        autofocus: Bool
    ) -> Update<AppModel, AppAction> {
        let fx: Fx<AppAction> = environment.database
            .readEntryDetail(slug: slug, template: template)
            .map({ detail in
                AppAction.updateDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(AppAction.failDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        return prepareRequestDetail(
            state: state,
            environment: environment,
            slug: slug
        )
        .mergeFx(fx)
    }

    /// Request detail for a random entry
    static func requestRandomDetail(
        state: AppModel,
        environment: AppEnvironment,
        autofocus: Bool
    ) -> Update<AppModel, AppAction> {
        let fx: Fx<AppAction> = environment.database.readRandomEntrySlug()
            .map({ slug in
                AppAction.requestDetail(
                    slug: slug,
                    fallback: slug.toTitle(),
                    autofocus: autofocus
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
        detail: EntryDetail,
        autofocus: Bool
    ) -> Update<AppModel, AppAction> {
        var model = resetEditor(state: state)

        model.editor.isLoading = false
        model.editor.slug = detail.slug
        model.editor.backlinks = detail.backlinks

        let headers: Headers = detail.entry.envelope.headers
        let body: Subtext = detail.entry.envelope.body

        // If headers are empty, create a default set of headers from
        // the subtext.
        model.editor.headers = headers

        // Schedule save for ~ after the transition animation completes.
        // If we save immediately, it causes list view to update while the
        // panel animates in, creating much visual noise.
        // By delaying the fx, we do this out of sight.
        // We don't actually know the exact time that the sliding panel
        // animation takes in NavigationView, so we estimate a time by which
        // the transition animation should be complete.
        // 2022-03-24 Gordon Brander
        let approximateNavigationViewAnimationCompleteDuration: Double = 1
        let fx: Fx<AppAction> = Just(AppAction.save)
            .delay(
                for: .seconds(
                    approximateNavigationViewAnimationCompleteDuration
                ),
                scheduler: DispatchQueue.main
            )
            .eraseToAnyPublisher()

        let update = Update(
            state: model,
            fx: fx
        )
        .pipe({ state in
            showDetail(
                state: state,
                environment: environment,
                isShowing: true
            )
        })
        .pipe({ state in
            setEditor(
                state: state,
                environment: environment,
                text: String(describing: body),
                saveState: detail.saveState
            )
        })

        // If editor is not meant to be focused, return early, setting focus
        // to nil.
        guard autofocus else {
            return update
                .pipe({ state in
                    setFocus(
                        state: state,
                        environment: environment,
                        focus: nil,
                        field: .editor
                    )
                })
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
                setFocus(
                    state: state,
                    environment: environment,
                    focus: .editor,
                    field: .editor
                )
            })
    }

    static func setLinkSheetPresented(
        state: AppModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<AppModel, AppAction> {
        var update = setFocus(
            state: state,
            environment: environment,
            focus: isPresented ? .linkSearch : .editor,
            field: .linkSearch
        )
        update.state.isLinkSheetPresented = isPresented
        return update
    }

    static func setLinkSearch(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel, AppAction> {
        /// Only change links if text has changed
        guard text != state.linkSearchText else {
            return Update(state: state)
        }
        var model = state
        model.linkSearchText = text

        // Omit current slug from results
        let omitting = state.editor.slug.mapOr(
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
        environment: AppEnvironment,
        suggestion: LinkSuggestion
    ) -> Update<AppModel, AppAction> {
        let link: EntryLink = Func.pipe(suggestion, { suggestion in
            switch suggestion {
            case .entry(let link):
                return link
            case .new(let link):
                return link
            }
        })

        // If there is a selected link, use that range
        // instead of selection
        let (range, replacement): (NSRange, String) = Func.pipe(
            state.editor.selectedEntryLinkMarkup,
            { markup in
                switch markup {
                case .slashlink(let slashlink):
                    let replacement = link.slug.toSlashlink()
                    let range = NSRange(
                        slashlink.span.range,
                        in: state.editor.text
                    )
                    return (range, replacement)
                case .wikilink(let wikilink):
                    let text = link.toLinkableTitle()
                    let replacement = Markup.Wikilink(text: text).markup
                    let range = NSRange(
                        wikilink.span.range,
                        in: state.editor.text
                    )
                    return (range, replacement)
                case .none:
                    let text = link.toLinkableTitle()
                    let replacement = Markup.Wikilink(text: text).markup
                    return (state.editor.selection, replacement)
                }
            }
        )

        var model = state
        model.linkSearchText = ""

        return Update(state: model)
            .pipe({ state in
                setLinkSheetPresented(
                    state: state,
                    environment: environment,
                    isPresented: false
                )
            })
            .pipe({ state in
                insertEditorText(
                    state: state,
                    environment: environment,
                    text: replacement,
                    range: range
                )
            })
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Save snapshot of entry
    static func save(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        // If editor dom is already saved, noop
        guard state.editor.saveState != .saved else {
            return Update(state: state)
        }

        // If there is no entry currently being edited, noop.
        guard let entry = SubtextFile(state.editor) else {
            let saveState = String(reflecting: state.editor.saveState)
            environment.logger.warning(
                "Entry save state is marked \(saveState) but no entry could be derived for state"
            )
            return Update(state: state)
        }

        var model = state
        // Mark saving in-progress
        model.editor.saveState = .saving

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
            model.editor.saveState == .saving &&
            model.isEditorMatchingEntry(entry)
        {
            model.editor.saveState = .saved
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
        model.editor.saveState = .modified
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
