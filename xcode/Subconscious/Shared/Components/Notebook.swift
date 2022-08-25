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
    case noop

    //  URL handlers
    case openURL(URL)
    case openEditorURL(URL)

    /// Set focus from a particular field
    case setFocus(
        focus: AppFocus?,
        field: AppFocus
    )

    /// Set focus from editor
    /// In addition to setting focus, this saves content on blur.
    case setEditorFocus(AppFocus?)

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
    case showRenameSheet(EntryLink?)
    case hideRenameSheet
    case setRenameField(String)
    case setRenameSuggestions([RenameSuggestion])
    case renameSuggestionsFailure(String)
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

extension NotebookAction {
    static func tagDetail(_ action: DetailAction) -> Self {
        switch action {
        case .setEditorText(let text):
            return .setEditor(
                text: text,
                saveState: .modified
            )
        case .setEditorSelection(let selection):
            return .setEditorSelection(selection)
        case .setFocus(let focus):
            return .setEditorFocus(focus)
        case .selectBacklink(let link):
            return .requestDetail(
                slug: link.slug,
                fallback: link.linkableTitle,
                autofocus: false
            )
        case .requestRename(let link):
            return .showRenameSheet(link)
        case .requestConfirmDelete(let slug):
            return .confirmDelete(slug)
        case .openEditorURL(let url):
            return .openEditorURL(url)
        }
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
/// Model containing state for the notebook tab.
struct NotebookModel: Hashable, Equatable {
    /// State reflecting global app focus state.
    var focus: AppFocus?

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
    /// Link to the candidate for renaming
    var entryToRename: EntryLink?
    /// Text for slug rename TextField.
    /// Note this is the contents of the search text field, which
    /// is different from the actual candidate slug to be renamed.
    var renameField: String = ""
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
        case .noop:
            return Update(state: state)
        case let .openURL(url):
            UIApplication.shared.open(url)
            return Update(state: state)
        case let .openEditorURL(url):
            return openEditorURL(state: state, url: url)
        case let .setFocus(focus, field):
            return setFocus(
                state: state,
                environment: environment,
                focus: focus,
                field: field
            )
        case let .setEditorFocus(focus):
            return setEditorFocus(
                state: state,
                environment: environment,
                focus: focus
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
        case let .showRenameSheet(entry):
            return showRenameSheet(
                state: state,
                environment: environment,
                entry: entry
            )
        case .hideRenameSheet:
            return hideRenameSheet(
                state: state,
                environment: environment
            )
        case let .setRenameField(text):
            return setRenameField(
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
        case let .renameEntry(suggestion):
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
        case let .failMoveEntry(error):
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
        case let .failMergeEntry(error):
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
        case let .failRetitleEntry(error):
            return failRetitleEntry(
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
                        focus: AppFocus.search,
                        field: AppFocus.search
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

    /// Set all editor properties to initial values
    static func resetEditor(state: NotebookModel) -> NotebookModel {
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
        state: NotebookModel,
        environment: AppEnvironment,
        text: String,
        saveState: SaveState = .modified
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment,
        range nsRange: NSRange
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        with withMarkup: (String) -> T
    ) -> Update<NotebookModel, NotebookAction>
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

    /// Set focus state.
    static func setFocus(
        state: NotebookModel,
        environment: AppEnvironment,
        focus: AppFocus?,
        field: AppFocus
    ) -> Update<NotebookModel, NotebookAction> {
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

    /// Manage focus while in an editing session.
    /// Does the same thing as `setFocus`, but also saves when editor
    /// loses focus.
    static func setEditorFocus(
        state: NotebookModel,
        environment: AppEnvironment,
        focus: AppFocus?
    ) -> Update<NotebookModel, NotebookAction> {
        let update = setFocus(
            state: state,
            environment: environment,
            focus: focus,
            field: .editor
        )
        // Check that focus was editor, and is being set to something else.
        // If not, return early.
        guard state.focus == .editor && focus != .editor else {
            return update
        }
        // Editor lost focus, save.
        return update.pipe({ state in
            save(state: state, environment: environment)
        })
    }

    /// Refresh all lists in the app from database
    /// Typically invoked after creating/deleting an entry, or performing
    /// some other action that would invalidate the state of various lists.
    static func refreshAll(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
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

    /// Reload and display detail for entry, and reload all list views
    static func requestDetailAndRefreshAll(
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<NotebookModel, NotebookAction> {
        requestDetail(
            state: state,
            environment: environment,
            slug: slug,
            fallback: "",
            autofocus: false
        )
        .pipe({ state in
            refreshAll(state: state, environment: environment)
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
        let fx: Fx<NotebookAction> = Just(NotebookAction.refreshAll)
            .eraseToAnyPublisher()

        var model = state
        // If we just deleted the entry currently being edited,
        // reset the editor to initial state (nothing is being edited).
        if state.editor.entryInfo?.slug == slug {
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
        state: NotebookModel,
        environment: AppEnvironment,
        entry: EntryLink?
    ) -> Update<NotebookModel, NotebookAction> {
        guard let entry = entry else {
            environment.logger.warning(
                "Rename sheet invoked on missing entry"
            )
            return Update(state: state)
        }

        var model = state
        model.isRenameSheetShowing = true
        model.entryToRename = entry

        let title = entry.linkableTitle

        return Update(state: model)
            //  Save entry in preperation for any merge/move.
            .pipe({ state in
                save(state: state, environment: environment)
            })
            //  Set rename slug field text
            .pipe({ state in
                setRenameField(
                    state: state,
                    environment: environment,
                    text: title
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
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.isRenameSheetShowing = false
        model.entryToRename = nil

        return Update(state: model)
            .pipe({ state in
                setRenameField(
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
    static func setRenameField(
        state: NotebookModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.renameField = text
        guard let current = state.entryToRename else {
            return Update(state: state)
        }
        let fx: Fx<NotebookAction> = environment.database
            .searchRenameSuggestions(
                query: text,
                current: current
            )
            .map({ suggestions in
                NotebookAction.setRenameSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    NotebookAction.renameSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }

    /// Set rename suggestions
    static func setRenameSuggestions(
        state: NotebookModel,
        suggestions: [RenameSuggestion]
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.renameSuggestions = suggestions
        return Update(state: model)
    }

    /// Handle rename suggestions error.
    /// This case can happen e.g. if the database fails to respond.
    static func renameSuggestionsError(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment,
        suggestion: RenameSuggestion
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = environment.database
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
        return hideRenameSheet(
            state: state,
            environment: environment
        )
        .mergeFx(fx)
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Move success lifecycle handler.
    /// Updates UI in response.
    static func succeedMoveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.log("Renamed entry from \(from.slug) to \(to.slug)")
        return requestDetailAndRefreshAll(
            state: state,
            environment: environment,
            slug: to.slug
        )
    }

    /// Move failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMoveEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = environment.database
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
        return hideRenameSheet(
            state: state,
            environment: environment
        )
        .mergeFx(fx)
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        parent: EntryLink,
        child: EntryLink
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.log(
            "Merged entry \(child.slug) into \(parent.slug)"
        )
        return requestDetailAndRefreshAll(
            state: state,
            environment: environment,
            slug: parent.slug
        )
    }

    /// Merge failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMergeEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel, NotebookAction> {
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
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = environment.database
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
        return hideRenameSheet(
            state: state,
            environment: environment
        )
        .mergeFx(fx)
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Retitle success lifecycle handler.
    /// Updates UI in response.
    static func succeedRetitleEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.log(
            "Retitled entry \(from.slug) to \(to.linkableTitle)"
        )
        return requestDetailAndRefreshAll(
            state: state,
            environment: environment,
            slug: from.slug
        )
    }

    /// Retitle failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failRetitleEntry(
        state: NotebookModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.warning(
            "Failed to retitle entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Unfocus editor and save current state
    static func selectDoneEditing(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
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

    /// Factors out the non-get-detail related aspects
    /// of requesting a detail view.
    /// Used by a few request detail implementations.
    private static func prepareRequestDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    ) -> Update<NotebookModel, NotebookAction> {
        // If nil slug was requested, do nothing
        guard let slug = slug else {
            environment.logger.log(
                "Detail requested for nil slug. Doing nothing."
            )
            return Update(state: state)
        }

        let fx: Fx<NotebookAction> = environment.database
            .readEntryDetail(
                slug: slug,
                // Trim whitespace and add blank line to end of string
                // This gives us a good starting point to start
                // editing.
                fallback: fallback
            )
            .map({ detail in
                NotebookAction.updateDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(NotebookAction.failDetail(error.localizedDescription))
            })
            .merge(
                with: Just(NotebookAction.setSearch("")),
                Just(NotebookAction.createSearchHistoryItem(fallback))
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
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug,
        template: Slug,
        autofocus: Bool
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = environment.database
            .readEntryDetail(slug: slug, template: template)
            .map({ detail in
                NotebookAction.updateDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(NotebookAction.failDetail(error.localizedDescription))
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
        state: NotebookModel,
        environment: AppEnvironment,
        autofocus: Bool
    ) -> Update<NotebookModel, NotebookAction> {
        let fx: Fx<NotebookAction> = environment.database.readRandomEntrySlug()
            .map({ slug in
                NotebookAction.requestDetail(
                    slug: slug,
                    fallback: slug.toTitle(),
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(NotebookAction.failRandomDetail(error))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Update entry detail.
    /// This case gets hit after requesting detail for an entry.
    static func updateDetail(
        state: NotebookModel,
        environment: AppEnvironment,
        detail: EntryDetail,
        autofocus: Bool
    ) -> Update<NotebookModel, NotebookAction> {
        var model = state
        model.editor = Editor(detail)

        // Schedule save for ~ after the transition animation completes.
        // If we save immediately, it causes list view to update while the
        // panel animates in, creating much visual noise.
        // By delaying the fx, we do this out of sight.
        // We don't actually know the exact time that the sliding panel
        // animation takes in NavigationView, so we estimate a time by which
        // the transition animation should be complete.
        // 2022-03-24 Gordon Brander
        let approximateNavigationViewAnimationCompleteDuration: Double = 1
        let fx: Fx<NotebookAction> = Just(NotebookAction.save)
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
                text: detail.entry.body,
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
        state: NotebookModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<NotebookModel, NotebookAction> {
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
        state: NotebookModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<NotebookModel, NotebookAction> {
        /// Only change links if text has changed
        guard text != state.linkSearchText else {
            return Update(state: state)
        }
        var model = state
        model.linkSearchText = text

        // Omit current slug from results
        let omitting = state.editor.entryInfo.mapOr(
            { info in Set([info.slug]) },
            default: Set()
        )

        // Get fallback link suggestions
        let fallback = environment.database.readDefaultLinkSuggestions()

        // Search link suggestions
        let fx: Fx<NotebookAction> = environment.database
            .searchLinkSuggestions(
                query: text,
                omitting: omitting,
                fallback: fallback
            )
            .map({ suggestions in
                NotebookAction.setLinkSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    NotebookAction.linkSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }

    static func selectLinkSuggestion(
        state: NotebookModel,
        environment: AppEnvironment,
        suggestion: LinkSuggestion
    ) -> Update<NotebookModel, NotebookAction> {
        let link: EntryLink = Func.pipe(
            suggestion,
            through: { suggestion in
                switch suggestion {
                case .entry(let link):
                    return link
                case .new(let link):
                    return link
                }
            }
        )

        // If there is a selected link, use that range
        // instead of selection
        let (range, replacement): (NSRange, String) = Func.pipe(
            state.editor.selectedEntryLinkMarkup,
            through: { markup in
                switch markup {
                case .slashlink(let slashlink):
                    let replacement = link.slug.toSlashlink()
                    let range = NSRange(
                        slashlink.span.range,
                        in: state.editor.text
                    )
                    return (range, replacement)
                case .wikilink(let wikilink):
                    let text = link.linkableTitle
                    let replacement = Markup.Wikilink(text: text).markup
                    let range = NSRange(
                        wikilink.span.range,
                        in: state.editor.text
                    )
                    return (range, replacement)
                case .none:
                    let text = link.linkableTitle
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

    /// Snapshot editor state in preparation for saving.
    /// Also mends header files.
    static func snapshotEditor(_ editor: Editor) -> SubtextFile? {
        guard let entry = SubtextFile(editor) else {
            return nil
        }
        return entry.modified(Date.now)
    }

    /// Save snapshot of entry
    static func save(
        state: NotebookModel,
        environment: AppEnvironment
    ) -> Update<NotebookModel, NotebookAction> {
        // If editor dom is already saved, noop
        guard state.editor.saveState != .saved else {
            return Update(state: state)
        }
        var model = state

        // Derive entry from editor
        guard let entry = snapshotEditor(model.editor) else {
            let saveState = String(reflecting: state.editor.saveState)
            environment.logger.warning(
                "Entry save state is marked \(saveState) but no entry could be derived for state. Doing nothing."
            )
            return Update(state: state)
        }

        // Mark saving in-progress
        model.editor.saveState = .saving

        let fx: Fx<NotebookAction> = environment.database
            .writeEntryAsync(entry)
            .map({ _ in
                NotebookAction.succeedSave(entry)
            })
            .catch({ error in
                Just(
                    NotebookAction.failSave(
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
        state: NotebookModel,
        environment: AppEnvironment,
        entry: SubtextFile
    ) -> Update<NotebookModel, NotebookAction> {
        environment.logger.debug(
            "Saved entry: \(entry.slug)"
        )
        let fx = Just(NotebookAction.refreshAll)
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
            model.editor.stateMatches(entry: entry)
        {
            model.editor.saveState = .saved
        }

        return Update(state: model, fx: fx)
    }

    static func failSave(
        state: NotebookModel,
        environment: AppEnvironment,
        slug: Slug,
        message: String
    ) -> Update<NotebookModel, NotebookAction> {
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

//  MARK: Mapping and tagging functions

extension NotebookModel {
    static func getDetail(_ model: NotebookModel) -> DetailModel {
        DetailModel(
            focus: model.focus,
            editor: model.editor
        )
    }
}

//  MARK: View
/// The file view for notes
struct NotebookView: View {
    var store: ViewStore<NotebookModel, NotebookAction>

    var isFabPresented: Bool {
        store.state.focus == nil
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
                            get: \.focus,
                            tag: { focus in
                                NotebookAction.setFocus(
                                    focus: focus,
                                    field: .search
                                )
                            }
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
                BottomSheetView(
                    isPresented: store.binding(
                        get: \.isRenameSheetShowing,
                        tag: { _ in NotebookAction.hideRenameSheet }
                    ),
                    height: geometry.size.height,
                    containerSize: geometry.size,
                    content: RenameSearchView(
                        current: store.state.editor.entryInfo.map({ info in
                            EntryLink(info)
                        }),
                        suggestions: store.state.renameSuggestions,
                        text: store.binding(
                            get: \.renameField,
                            tag: NotebookAction.setRenameField
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: { focus in
                                NotebookAction.setFocus(
                                    focus: focus,
                                    field: .rename
                                )
                            }
                        ),
                        onCancel: {
                            store.send(.hideRenameSheet)
                        },
                        onSelect: { suggestion in
                            store.send(
                                .renameEntry(suggestion)
                            )
                        }
                    )
                )
                .zIndex(4)
                BottomSheetView(
                    isPresented: store.binding(
                        get: \.isLinkSheetPresented,
                        tag: NotebookAction.setLinkSheetPresented
                    ),
                    height: geometry.size.height,
                    containerSize: geometry.size,
                    content: LinkSearchView(
                        placeholder: "Search or create...",
                        suggestions: store.state.linkSuggestions,
                        text: store.binding(
                            get: \.linkSearchText,
                            tag: NotebookAction.setLinkSearch
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: { focus in
                                NotebookAction.setFocus(
                                    focus: focus,
                                    field: .linkSearch
                                )
                            }
                        ),
                        onCancel: {
                            store.send(.setLinkSheetPresented(false))
                        },
                        onSelect: { suggestion in
                            store.send(.selectLinkSuggestion(suggestion))
                        }
                    )
                )
                .zIndex(4)
            }
        }
        .background(.red)
    }
}
