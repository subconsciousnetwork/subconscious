//
//  DetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI
import os
import ObservableStore
import Combine

//  MARK: Action
enum DetailAction: Hashable, CustomLogStringConvertible {
    /// Wrapper for editor actions
    case markupEditor(MarkupTextAction)

    case openEditorURL(URL)
    /// Invokes save and blurs editor
    case selectDoneEditing


    // Detail
    /// Load detail
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
    case failDetail(String)
    case failRandomDetail(String)
    case showDetail(Bool)
    /// Update entry being displayed
    case updateDetail(detail: EntryDetail, autofocus: Bool)
    /// Set detail to initial conditions
    case resetDetail

    //  Saving entry
    /// Trigger autosave of current state
    case autosave
    /// Save an entry at a particular snapshot value
    case save(SubtextFile?)
    case succeedSave(SubtextFile)
    case failSave(
        slug: Slug,
        message: String
    )

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearch(String)
    case refreshLinkSuggestions
    case selectLinkSuggestion(LinkSuggestion)
    case setLinkSuggestions([LinkSuggestion])
    case linkSuggestionsFailure(String)

    // Rename
    case showRenameSheet(EntryLink?)
    case hideRenameSheet
    case setRenameField(String)
    case refreshRenameSuggestions
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

    case selectBacklink(EntryLink)
    case requestConfirmDelete(Slug)

    // Editor
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

    /// Refresh after save
    case refreshAll

    static func requestEditorFocus(_ isFocused: Bool) -> Self {
        .markupEditor(.requestFocus(isFocused))
    }

    /// Update editor dom and always mark modified
    static func modifyEditor(text: String) -> Self {
        Self.setEditor(text: text, saveState: .modified)
    }

    /// Select a link completion
    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
    }

    var logDescription: String {
        switch self {
        case .setLinkSuggestions(let suggestions):
            return "setLinkSuggestions(\(suggestions.count) items)"
        case .setRenameSuggestions(let suggestions):
            return "setRenameSuggestions(\(suggestions.count) items)"
        case .markupEditor(let action):
            return "markupEditor(\(String.loggable(action)))"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Cursors
/// Editor cursor
struct DetailMarkupEditorCursor: CursorProtocol {
    static func get(state: DetailModel) -> MarkupTextModel {
        state.markupEditor
    }

    static func set(state: DetailModel, inner: MarkupTextModel) -> DetailModel {
        var model = state
        model.markupEditor = inner
        return model
    }

    static func tag(action: MarkupTextAction) -> DetailAction {
        switch action {
        // Intercept text set action so we can mark all text-sets
        // as dirty.
        case .setText(let text):
            return .setEditor(text: text, saveState: .modified)
        // Intercept setSelection, so we can set link suggestions based on
        // cursor position.
        case .setSelection(let nsRange):
            return .setEditorSelection(nsRange)
        default:
            return .markupEditor(action)
        }
    }
}

//  MARK: Model
struct DetailModel: Hashable {
    var slug: Slug?
    var headers: HeaderIndex = .empty
    var backlinks: [EntryStub] = []

    /// Is editor saved?
    var saveState = SaveState.saved

    /// Is editor in loading state?
    var isLoading = true

    /// The entry link within the text
    var selectedEntryLinkMarkup: Subtext.EntryLinkMarkup?

    /// The text editor
    var markupEditor = MarkupTextModel()

    /// Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var linkSearchText = ""
    var linkSuggestions: [LinkSuggestion] = []

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

    /// Given a particular entry value, does the editor's state
    /// currently match it, such that we could say the editor is
    /// displaying that entry?
    func stateMatches(entry: SubtextFile) -> Bool {
        guard let slug = self.slug else {
            return false
        }
        return (
            slug == entry.slug &&
            markupEditor.text == entry.body
        )
    }

    //  MARK: Update
    static func update(
        state: DetailModel,
        action: DetailAction,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        switch action {
        case .markupEditor(let action):
            return DetailMarkupEditorCursor.update(
                with: MarkupTextModel.update,
                state: state,
                action: action,
                environment: ()
            )
        case .openEditorURL(_):
            return logDebug(
                state: state,
                environment: environment,
                message: "openEditorURL should be handled by parent component"
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
        case .selectDoneEditing:
            return selectDoneEditing(
                state: state,
                environment: environment
            )
        case .showDetail:
            return logDebug(
                state: state,
                environment: environment,
                message: ".showDetail should be handled by parent component"
            )
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
        case let .failDetail(message):
            environment.logger.log(
                "Failed to get details for search: \(message)"
            )
            return Update(state: state)
        case .failRandomDetail(let message):
            return logWarning(
                state: state,
                environment: environment,
                message: message
            )
        case let .updateDetail(results, autofocus):
            return updateDetail(
                state: state,
                environment: environment,
                detail: results,
                autofocus: autofocus
            )
        case .resetDetail:
            return resetDetail(
                state: state,
                environment: environment
            )
        case .autosave:
            return autosave(
                state: state,
                environment: environment
            )
        case .save(let entry):
            return save(
                state: state,
                environment: environment,
                entry: entry
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
        case .refreshLinkSuggestions:
            return setLinkSearch(
                state: state,
                environment: environment,
                text: state.linkSearchText
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
        case .refreshRenameSuggestions:
            return setRenameField(
                state: state,
                environment: environment,
                text: state.renameField
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
        case .selectBacklink(_):
            return logDebug(
                state: state,
                environment: environment,
                message: "selectBacklink should be handled by parent component"
            )
        case .requestConfirmDelete(_):
            return logDebug(
                state: state,
                environment: environment,
                message: "requestConfirmDelete should be handled by parent component"
            )
        case .insertEditorWikilinkAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.markupEditor.selection,
                with: { text in Markup.Wikilink(text: text) }
            )
        case .insertEditorBoldAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.markupEditor.selection,
                with: { text in Markup.Bold(text: text) }
            )
        case .insertEditorItalicAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.markupEditor.selection,
                with: { text in Markup.Italic(text: text) }
            )
        case .insertEditorCodeAtSelection:
            return insertTaggedMarkup(
                state: state,
                environment: environment,
                range: state.markupEditor.selection,
                with: { text in Markup.Code(text: text) }
            )
        case .refreshAll:
            return refreshAll(
                state: state,
                environment: environment
            )
        }
    }

    /// Log debug
    static func logDebug(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.debug("\(message)")
        return Update(state: state)
    }

    /// Log debug
    static func logWarning(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.warning("\(message)")
        return Update(state: state)
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
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        saveState: SaveState = .modified
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = Just(
            DetailAction.markupEditor(.setText(text))
        )
        .eraseToAnyPublisher()

        var model = state
        // Mark save state
        model.saveState = saveState

        return Update(state: model, fx: fx)
    }

    /// Set editor selection.
    static func setEditorSelection(
        state: DetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = Just(
            DetailAction.markupEditor(.setSelection(nsRange))
        )
        .eraseToAnyPublisher()

        var model = state

        let dom = Subtext.parse(markup: state.markupEditor.text)
        let link = dom.entryLinkFor(range: nsRange)
        model.selectedEntryLinkMarkup = link

        let linkSearchText = link?.toTitle() ?? ""

        return Update(state: model, fx: fx)
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
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        let range = NSRange(
            state.markupEditor.text.endIndex...,
            in: state.markupEditor.text
        )

        return setEditorSelection(
            state: state,
            environment: environment,
            range: range
        )
    }

    /// Insert text in editor at range
    static func insertEditorText(
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<DetailModel, DetailAction> {
        guard let range = Range(nsRange, in: state.markupEditor.text) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        // Replace selected range with committed link search text.
        let markup = state.markupEditor.text.replacingCharacters(
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

    /// Unfocus editor and save current state
    static func selectDoneEditing(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = Just(
            DetailAction.requestEditorFocus(false)
        )
        .merge(with: Just(DetailAction.autosave))
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Factors out the non-get-detail related aspects
    /// of requesting a detail view.
    /// Used by a few request detail implementations.
    private static func prepareRequestDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.isLoading = true
        return autosave(state: model, environment: environment)
    }

    /// Request detail view for entry.
    /// Fall back on string (typically query string) when no detail
    /// exists for this slug yet.
    static func requestDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    ) -> Update<DetailModel, DetailAction> {
        // If nil slug was requested, do nothing
        guard let slug = slug else {
            environment.logger.log(
                "Detail requested for nil slug. Doing nothing."
            )
            return Update(state: state)
        }

        let fx: Fx<DetailAction> = environment.database
            .readEntryDetail(
                slug: slug,
                // Trim whitespace and add blank line to end of string
                // This gives us a good starting point to start
                // editing.
                fallback: fallback
            )
            .map({ detail in
                DetailAction.updateDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(DetailAction.failDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        return prepareRequestDetail(
            state: state,
            environment: environment,
            slug: slug
        )
        .mergeFx(fx)
    }

    /// Reload and display detail for entry, and reload all list views
    static func requestDetailAndRefreshAll(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<DetailModel, DetailAction> {
        let refreshFx: Fx<DetailAction> = Just(
            DetailAction.refreshAll
        )
        .eraseToAnyPublisher()

        let fx: Fx<DetailAction> = Just(
            DetailAction.requestDetail(
                slug: slug,
                fallback: "",
                autofocus: false
            )
        )
        .merge(
            with: refreshFx
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    /// Request detail view for entry.
    /// Fall back on contents of template file when no detail
    /// exists for this slug yet.
    static func requestTemplateDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug,
        template: Slug,
        autofocus: Bool
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = environment.database
            .readEntryDetail(slug: slug, template: template)
            .map({ detail in
                DetailAction.updateDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(DetailAction.failDetail(error.localizedDescription))
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
        state: DetailModel,
        environment: AppEnvironment,
        autofocus: Bool
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = environment.database.readRandomEntrySlug()
            .map({ slug in
                DetailAction.requestDetail(
                    slug: slug,
                    fallback: slug.toTitle(),
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(DetailAction.failRandomDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Update entry detail.
    /// This case gets hit after requesting detail for an entry.
    static func updateDetail(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail,
        autofocus: Bool
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = Just(
            DetailAction.showDetail(true)
        )
        .eraseToAnyPublisher()

        // If we just loaded the detail we're already editing, do not
        // blow it away. Just mark loading complete and show detail.
        // The in-memory version we are editing should win.
        guard state.slug != detail.slug else {
            environment.logger.log(
                "Entry already being edited. Using in-memory version."
            )
            var model = state
            model.isLoading = false
            return Update(state: model, fx: fx)
        }

        // Schedule save for ~ after the transition animation completes.
        // If we save immediately, it causes list view to update while the
        // panel animates in, creating much visual noise.
        // By delaying the fx, we do this out of sight.
        // We don't actually know the exact time that the sliding panel
        // animation takes in NavigationView, so we estimate a time by which
        // the transition animation should be complete.
        // 2022-03-24 Gordon Brander
        let approximateNavigationViewAnimationCompleteDuration: Double = 1

        // Snapshot entry and schedule a save before we replace it.
        let snapshot = state.snapshotEntry()
        let saveFx: Fx<DetailAction> = Just(DetailAction.save(snapshot))
            .delay(
                for: .seconds(
                    approximateNavigationViewAnimationCompleteDuration
                ),
                scheduler: DispatchQueue.main
            )
            .eraseToAnyPublisher()

        var model = state
        model.isLoading = false
        model.slug = detail.slug
        model.headers = detail.entry.headers
        model.backlinks = detail.backlinks
        model.saveState = .saved

        let update = Update(
            state: model,
            fx: fx.merge(with: saveFx).eraseToAnyPublisher()
        )
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
            let focusFx: Fx<DetailAction> = Just(
                DetailAction.requestEditorFocus(false)
            )
            .eraseToAnyPublisher()
            return update.mergeFx(focusFx)
        }

        // Otherwise, set editor selection and focus to end of document.
        // When you've just created a new note, chances are you want to
        // edit it, not browse it.
        // We focus the editor and place the cursor at the end so you can just
        // start typing

        let focusFx: Fx<DetailAction> = Just(
            DetailAction.requestEditorFocus(true)
        )
        .eraseToAnyPublisher()

        return update
            .pipe({ state in
                setEditorSelectionEnd(
                    state: state,
                    environment: environment
                )
            })
            .mergeFx(focusFx)
    }

    /// Reset model to "none" condition
    static func resetDetail(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.slug = nil
        model.markupEditor = MarkupTextModel()
        model.backlinks = []
        model.isLoading = true
        model.saveState = .saved
        return Update(state: state)
    }

    static func autosave(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        let entry = state.snapshotEntry()
        return save(
            state: state,
            environment: environment,
            entry: entry
        )
    }

    /// Save snapshot of entry
    static func save(
        state: DetailModel,
        environment: AppEnvironment,
        entry: SubtextFile?
    ) -> Update<DetailModel, DetailAction> {
        // If editor dom is already saved, noop
        guard state.saveState != .saved else {
            return Update(state: state)
        }
        // If there is no entry, nothing to save
        guard let entry = entry else {
            let saveState = String(reflecting: state.saveState)
            environment.logger.warning(
                "Entry save state is marked \(saveState) but no entry could be derived for state. Doing nothing."
            )
            return Update(state: state)
        }

        var model = state

        // Mark saving in-progress
        model.saveState = .saving

        let fx: Fx<DetailAction> = environment.database
            .writeEntryAsync(entry)
            .map({ _ in
                DetailAction.succeedSave(entry)
            })
            .catch({ error in
                Just(
                    DetailAction.failSave(
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
        state: DetailModel,
        environment: AppEnvironment,
        entry: SubtextFile
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.debug(
            "Saved entry: \(entry.slug)"
        )
        let fx = Just(DetailAction.refreshAll)
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
            model.saveState == .saving &&
            model.stateMatches(entry: entry)
        {
            model.saveState = .saved
        }

        return Update(state: model, fx: fx)
    }

    static func failSave(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug,
        message: String
    ) -> Update<DetailModel, DetailAction> {
        //  TODO: show user a "try again" banner
        environment.logger.warning(
            "Save failed for entry (\(slug)) with error: \(message)"
        )
        // Mark modified, since we failed to save
        var model = state
        model.saveState = .modified
        return Update(state: model)
    }

    static func setLinkSheetPresented(
        state: DetailModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.isLinkSheetPresented = isPresented
        return Update(state: model)
    }

    static func setLinkSearch(
        state: DetailModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.linkSearchText = text

        // Omit current slug from results
        let omitting = state.slug.mapOr(
            { slug in Set([slug]) },
            default: Set()
        )

        // Get fallback link suggestions
        let fallback = environment.database.readDefaultLinkSuggestions()

        // Search link suggestions
        let fx: Fx<DetailAction> = environment.database
            .searchLinkSuggestions(
                query: text,
                omitting: omitting,
                fallback: fallback
            )
            .map({ suggestions in
                DetailAction.setLinkSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    DetailAction.linkSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }

    static func selectLinkSuggestion(
        state: DetailModel,
        environment: AppEnvironment,
        suggestion: LinkSuggestion
    ) -> Update<DetailModel, DetailAction> {
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
            state.selectedEntryLinkMarkup,
            through: { markup in
                switch markup {
                case .slashlink(let slashlink):
                    let replacement = link.slug.toSlashlink()
                    let range = NSRange(
                        slashlink.span.range,
                        in: state.markupEditor.text
                    )
                    return (range, replacement)
                case .wikilink(let wikilink):
                    let text = link.linkableTitle
                    let replacement = Markup.Wikilink(text: text).markup
                    let range = NSRange(
                        wikilink.span.range,
                        in: state.markupEditor.text
                    )
                    return (range, replacement)
                case .none:
                    let text = link.linkableTitle
                    let replacement = Markup.Wikilink(text: text).markup
                    return (state.markupEditor.selection, replacement)
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

    /// Show rename sheet.
    /// Do rename-flow-related setup.
    static func showRenameSheet(
        state: DetailModel,
        environment: AppEnvironment,
        entry: EntryLink?
    ) -> Update<DetailModel, DetailAction> {
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
                autosave(
                    state: state,
                    environment: environment
                )
            })
            //  Set rename slug field text
            .pipe({ state in
                setRenameField(
                    state: state,
                    environment: environment,
                    text: title
                )
            })
    }

    /// Hide rename sheet.
    /// Do rename-flow-related teardown.
    static func hideRenameSheet(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
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
    }

    /// Set text of slug field
    static func setRenameField(
        state: DetailModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.renameField = text
        guard let current = state.entryToRename else {
            return Update(state: state)
        }
        let fx: Fx<DetailAction> = environment.database
            .searchRenameSuggestions(
                query: text,
                current: current
            )
            .map({ suggestions in
                DetailAction.setRenameSuggestions(suggestions)
            })
            .catch({ error in
                Just(
                    DetailAction.renameSuggestionsFailure(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }

    /// Set rename suggestions
    static func setRenameSuggestions(
        state: DetailModel,
        suggestions: [RenameSuggestion]
    ) -> Update<DetailModel, DetailAction> {
        var model = state
        model.renameSuggestions = suggestions
        return Update(state: model)
    }

    /// Handle rename suggestions error.
    /// This case can happen e.g. if the database fails to respond.
    static func renameSuggestionsError(
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel, DetailAction> {
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
        state: DetailModel,
        environment: AppEnvironment,
        suggestion: RenameSuggestion
    ) -> Update<DetailModel, DetailAction> {
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
        state: DetailModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = environment.database
            .moveEntryAsync(from: from, to: to)
            .map({ _ in
                DetailAction.succeedMoveEntry(from: from, to: to)
            })
            .catch({ error in
                Just(
                    DetailAction.failMoveEntry(
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
        state: DetailModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<DetailModel, DetailAction> {
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
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.warning(
            "Failed to move entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Merge entry
    static func mergeEntry(
        state: DetailModel,
        environment: AppEnvironment,
        parent: EntryLink,
        child: EntryLink
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = environment.database
            .mergeEntryAsync(parent: parent, child: child)
            .map({ _ in
                DetailAction.succeedMergeEntry(parent: parent, child: child)
            })
            .catch({ error in
                Just(
                    DetailAction.failMergeEntry(error.localizedDescription)
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
        state: DetailModel,
        environment: AppEnvironment,
        parent: EntryLink,
        child: EntryLink
    ) -> Update<DetailModel, DetailAction> {
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
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.warning(
            "Failed to merge entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Retitle entry
    static func retitleEntry(
        state: DetailModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = environment.database
            .retitleEntryAsync(from: from, to: to)
            .map({ _ in
                DetailAction.succeedRetitleEntry(from: from, to: to)
            })
            .catch({ error in
                Just(
                    DetailAction.failRetitleEntry(
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
        state: DetailModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.log(
            "Retitled entry \(from.slug) to \(to.linkableTitle)"
        )

        /// Refresh lists since we changed the title
        let fx: Fx<DetailAction> = Just(
            DetailAction.refreshAll
        )
        .eraseToAnyPublisher()

        /// We succeeded in updating title header on disk.
        /// Now set it in the view, so we see the updated state.
        var model = state
        model.headers["title"] = to.linkableTitle

        return Update(state: model, fx: fx)
    }

    /// Retitle failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failRetitleEntry(
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel, DetailAction> {
        environment.logger.warning(
            "Failed to retitle entry with error: \(error)"
        )
        return Update(state: state)
    }


    /// Insert wikilink markup into editor, begining at previous range
    /// and wrapping the contents of previous range
    static func insertTaggedMarkup<T>(
        state: DetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        with withMarkup: (String) -> T
    ) -> Update<DetailModel, DetailAction>
    where T: TaggedMarkup
    {
        guard let range = Range(nsRange, in: state.markupEditor.text) else {
            environment.logger.log(
                "Cannot replace text. Invalid range: \(nsRange))"
            )
            return Update(state: state)
        }

        let selectedText = String(state.markupEditor.text[range])
        let markup = withMarkup(selectedText)

        // Replace selected range with committed link search text.
        let editorText = state.markupEditor.text.replacingCharacters(
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

    /// Dispatch refresh actions
    static func refreshAll(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel, DetailAction> {
        let fx: Fx<DetailAction> = Just(
            DetailAction.refreshRenameSuggestions
        )
        .merge(
            with: Just(DetailAction.refreshLinkSuggestions)
        )
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Snapshot editor state in preparation for saving.
    /// Also mends header files.
    func snapshotEntry() -> SubtextFile? {
        guard let entry = SubtextFile(self) else {
            return nil
        }
        return entry.modified(Date.now)
    }
}

extension EntryLink {
    init?(_ detail: DetailModel) {
        guard let slug = detail.slug else {
            return nil
        }
        guard let title = detail.headers["title"] else {
            self.init(slug: slug)
            return
        }
        self.init(slug: slug, title: title)
    }
}

extension SubtextFile {
    /// Initialize SubtextFile from DetailModel.
    /// We use this to snapshot the current state of detail for saving.
    init?(_ detail: DetailModel) {
        guard let slug = detail.slug else {
            return nil
        }
        self.slug = slug
        self.headers = detail.headers
        self.body = detail.markupEditor.text
    }
}

//  MARK: View
struct DetailView: View {
    private static func calcTextFieldHeight(
        containerHeight: CGFloat,
        isKeyboardUp: Bool,
        hasBacklinks: Bool
    ) -> CGFloat {
        UIFont.appTextMono.lineHeight * 8
    }

    var store: ViewStore<DetailModel, DetailAction>

    var isReady: Bool {
        let state = store.state
        return !state.isLoading && state.slug != nil
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Divider()
                        ScrollView(.vertical) {
                            VStack(spacing: 0) {
                                MarkupTextViewRepresentable(
                                    store: store.viewStore(
                                        get: DetailMarkupEditorCursor.get,
                                        tag: DetailMarkupEditorCursor.tag
                                    ),
                                    frame: geometry.frame(in: .local),
                                    renderAttributesOf: Subtext.renderAttributesOf,
                                    onLink: { url, _, _, _ in
                                        store.send(.openEditorURL(url))
                                        return false
                                    },
                                    logger: Logger.editor
                                )
                                .insets(
                                    EdgeInsets(
                                        top: AppTheme.padding,
                                        leading: AppTheme.padding,
                                        bottom: AppTheme.padding,
                                        trailing: AppTheme.padding
                                    )
                                )
                                .frame(
                                    minHeight: Self.calcTextFieldHeight(
                                        containerHeight: geometry.size.height,
                                        isKeyboardUp: store.state.markupEditor.focus,
                                        hasBacklinks: store.state.backlinks.count > 0
                                    )
                                )
                                ThickDividerView()
                                    .padding(.bottom, AppTheme.unit4)
                                BacklinksView(
                                    backlinks: store.state.backlinks,
                                    onSelect: { link in
                                        store.send(.selectBacklink(link))
                                    }
                                )
                            }
                        }
                    if store.state.markupEditor.focus {
                        DetailKeyboardToolbarView(
                            isSheetPresented: store.binding(
                                get: \.isLinkSheetPresented,
                                tag: DetailAction.setLinkSheetPresented
                            ),
                            selectedEntryLinkMarkup:
                                store.state.selectedEntryLinkMarkup,
                            suggestions: store.state.linkSuggestions,
                            onSelectLinkCompletion: { link in
                                store.send(.selectLinkCompletion(link))
                            },
                            onInsertWikilink: {
                                store.send(.insertEditorWikilinkAtSelection)
                            },
                            onInsertBold: {
                                store.send(.insertEditorBoldAtSelection)
                            },
                            onInsertItalic: {
                                store.send(.insertEditorItalicAtSelection)
                            },
                            onInsertCode: {
                                store.send(.insertEditorCodeAtSelection)
                            },
                            onDoneEditing: {
                                store.send(.selectDoneEditing)
                            }
                        )
                        .transition(
                            .asymmetric(
                                insertion: .opacity.animation(
                                    .easeOutCubic(duration: Duration.normal)
                                    .delay(Duration.keyboard)
                                ),
                                removal: .opacity.animation(
                                    .easeOutCubic(duration: Duration.normal)
                                )
                            )
                        )
                    }
                }
                .zIndex(1)
                if !isReady {
                    Color.background
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.animation(.none),
                                removal: .opacity.animation(.default)
                            )
                        )
                        .zIndex(2)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            isPresented: store.binding(
                get: \.isLinkSheetPresented,
                tag: DetailAction.setLinkSheetPresented
            )
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                suggestions: store.state.linkSuggestions,
                text: store.binding(
                    get: \.linkSearchText,
                    tag: DetailAction.setLinkSearch
                ),
                onCancel: {
                    store.send(.setLinkSheetPresented(false))
                },
                onSelect: { suggestion in
                    store.send(.selectLinkSuggestion(suggestion))
                }
            )
        }
        .sheet(
            isPresented: store.binding(
                get: \.isRenameSheetShowing,
                tag: { _ in DetailAction.hideRenameSheet }
            )
        ) {
            RenameSearchView(
                current: EntryLink(store.state),
                suggestions: store.state.renameSuggestions,
                text: store.binding(
                    get: \.renameField,
                    tag: DetailAction.setRenameField
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
        }
        .toolbar {
            DetailToolbarContent(
                link: EntryLink(store.state),
                onRename: {
                    store.send(.showRenameSheet(EntryLink(store.state)))
                },
                onDelete: {
                    if let slug = store.state.slug {
                        store.send(.requestConfirmDelete(slug))
                    }
                }
            )
        }
    }
}
