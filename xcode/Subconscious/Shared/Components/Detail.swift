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

    /// Link was tapped (disambiguates to browser or editor action)
    case openURL(URL)
    case openBrowserURL(URL)
    case openEditorURL(URL)

    // Detail
    /// Load detail, using a last-write-wins strategy for replacement
    /// if detail is already loaded.
    case loadAndPresentDetail(slug: Slug?, fallback: String, autofocus: Bool)
    /// Reload detail from source of truth
    case refreshDetail
    case refreshDetailIfStale
    /// Unable to load detail
    case failLoadDetail(String)
    /// Set entry detail.
    /// This actions will blow away any existing entry detail.
    /// In most cases you want to use `setDetailLastWriteWins` instead.
    case forceSetDetail(EntryDetail)
    /// Set EntryDetail on DetailModel, but only if last modification happened
    /// more recently than DetailModel.
    case setDetailLastWriteWins(EntryDetail)
    /// Set detail and present detail
    case setAndPresentDetail(detail: EntryDetail, autofocus: Bool)
    /// Load detail
    /// request detail for slug, using template file as a fallback
    case loadAndPresentTemplateDetail(
        slug: Slug,
        template: Slug,
        autofocus: Bool
    )
    case loadAndPresentRandomDetail(autofocus: Bool)
    /// Show detail panel
    case presentDetail(Bool)
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

    //  Delete entry requests
    /// Show/hide delete confirmation dialog
    case showDeleteConfirmationDialog(Bool)
    /// Request that parent delete entry
    case requestDeleteEntry(Slug?)
    case entryDeleted(Slug)

    case selectBacklink(EntryLink)

    // Editor
    /// Update editor dom and mark if this state is saved or not
    case setEditor(
        text: String,
        saveState: SaveState,
        modified: Date
    )

    /// Editor focus state changed.
    /// We intercept this editor action to save editor contents
    /// when editor focus changes to false.
    case editorFocusChange(Bool)

    /// Set selected range in editor
    case setEditorSelection(range: NSRange, text: String)
    case setEditorSelectionEnd
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
    case refreshLists

    /// Synonym for requesting editor blur.
    static var selectDoneEditing: Self {
        .markupEditor(.requestFocus(false))
    }

    /// Select a link completion
    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
    }

    /// Generate a detail request from a suggestion
    static func fromSuggestion(_ suggestion: Suggestion) -> Self {
        switch suggestion {
        case .entry(let entryLink):
            return .loadAndPresentDetail(
                slug: entryLink.slug,
                fallback: entryLink.linkableTitle,
                autofocus: false
            )
        case .search(let entryLink):
            return .loadAndPresentDetail(
                slug: entryLink.slug,
                fallback: entryLink.linkableTitle,
                autofocus: true
            )
        case .journal(let entryLink):
            return .loadAndPresentTemplateDetail(
                slug: entryLink.slug,
                template: Config.default.journalTemplate,
                // Autofocus note because we're creating it from scratch
                autofocus: true
            )
        case .scratch(let entryLink):
            return .loadAndPresentDetail(
                slug: entryLink.slug,
                fallback: entryLink.linkableTitle,
                autofocus: true
            )
        case .random:
            return .loadAndPresentRandomDetail(autofocus: false)
        }
    }

    // MARK: logDescription
    var logDescription: String {
        switch self {
        case .setLinkSuggestions(let suggestions):
            return "setLinkSuggestions(\(suggestions.count) items)"
        case .setRenameSuggestions(let suggestions):
            return "setRenameSuggestions(\(suggestions.count) items)"
        case .markupEditor(let action):
            return "markupEditor(\(String.loggable(action)))"
        case let .setDetailLastWriteWins(detail):
            return "setDetailLastWriteWins(\(String.loggable(detail)))"
        case .save(let entry):
            let slugString: String = entry.mapOr(
                { entry in String(entry.slug) },
                default: "nil"
            )
            return "save(\(slugString))"
        case .succeedSave(let entry):
            return "succeedSave(\(entry.slug))"
        case .setAndPresentDetail(let detail, _):
            return "setAndPresentDetail(\(String.loggable(detail)))"
        case let .setEditor(_, saveState, modified):
            return "setEditor(text: ..., saveState: \(String(describing: saveState)), modified: \(modified))"
        case let .setEditorSelection(range, _):
            return "setEditorSelection(range: \(range), text: ...)"
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

    static func tag(_ action: MarkupTextAction) -> DetailAction {
        switch action {
        // Intercept text set action so we can mark all text-sets
        // as dirty.
        case .setText(let text):
            return .setEditor(
                text: text,
                saveState: .modified,
                modified: .now
            )
        // Intercept requestFocus, so we can save on blur.
        case let .focusChange(isFocused):
            return .editorFocusChange(isFocused)
        // Intercept setSelection, so we can set link suggestions based on
        // cursor position.
        case let .setSelection(nsRange, text):
            return .setEditorSelection(range: nsRange, text: text)
        default:
            return .markupEditor(action)
        }
    }
}

//  MARK: Model
struct DetailModel: ModelProtocol {
    var slug: Slug?
    var headers: HeaderIndex = .empty
    var backlinks: [EntryStub] = []

    /// Is editor saved?
    var saveState = SaveState.saved
    /// Initialize date with Unix Epoch
    var modified = Date.distantPast

    /// Is editor sliding panel showing?
    var isPresented = false
    /// Is editor in loading state?
    var isLoading = true
    /// When was the last time the editor issued a fetch from source of truth?
    var lastLoadStarted = Date.distantPast
    /// Time interval after which a load is considered stale, and should be
    /// reloaded to make sure it is fresh.
    var loadStaleInterval: TimeInterval = 0.2

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

    /// Is delete confirmation dialog presented?
    var isDeleteConfirmationDialogShowing = false

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
    ) -> Update<DetailModel> {
        switch action {
        case .markupEditor(let action):
            return DetailMarkupEditorCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .openURL(let url):
            return openURL(
                state: state,
                environment: environment,
                url: url
            )
        case .openBrowserURL(let url):
            return openBrowserURL(
                state: state,
                environment: environment,
                url: url
            )
        case .openEditorURL(let url):
            return openEditorURL(
                state: state,
                environment: environment,
                url: url
            )
        case let .setEditor(text, saveState, modified):
            return setEditor(
                state: state,
                environment: environment,
                text: text,
                saveState: saveState,
                modified: modified
            )
        case let .editorFocusChange(isFocused):
            return editorFocusChange(
                state: state,
                environment: environment,
                isFocused: isFocused
            )
        case let .setEditorSelection(range, text):
            return setEditorSelection(
                state: state,
                environment: environment,
                range: range,
                text: text
            )
        case .setEditorSelectionEnd:
            return setEditorSelectionEnd(
                state: state,
                environment: environment
            )
        case let .insertEditorText(text, range):
            return insertEditorText(
                state: state,
                environment: environment,
                text: text,
                range: range
            )
        case .presentDetail(let isPresented):
            return presentDetail(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case let .loadAndPresentDetail(slug, fallback, autofocus):
            return loadAndPresentDetail(
                state: state,
                environment: environment,
                slug: slug,
                fallback: fallback,
                autofocus: autofocus
            )
        case .refreshDetail:
            return refreshDetail(
                state: state,
                environment: environment
            )
        case .refreshDetailIfStale:
            return refreshDetailIfStale(
                state: state,
                environment: environment
            )
        case let .failLoadDetail(message):
            return failLoadDetail(
                state: state,
                environment: environment,
                message: message
            )
        case .forceSetDetail(let detail):
            return forceSetDetail(
                state: state,
                environment: environment,
                detail: detail
            )
        case let .setAndPresentDetail(detail, autofocus):
            return setAndPresentDetail(
                state: state,
                environment: environment,
                detail: detail,
                autofocus: autofocus
            )
        case .setDetailLastWriteWins(let detail):
            return setDetailLastWriteWins(
                state: state,
                environment: environment,
                detail: detail
            )
        case let .loadAndPresentTemplateDetail(slug, template, autofocus):
            return loadAndPresentTemplateDetail(
                state: state,
                environment: environment,
                slug: slug,
                template: template,
                autofocus: autofocus
            )
        case let .loadAndPresentRandomDetail(autofocus):
            return loadAndPresentRandomDetail(
                state: state,
                environment: environment,
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
        case .showDeleteConfirmationDialog(let isPresented):
            return presentDeleteConfirmationDialog(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .requestDeleteEntry(_):
            return logDebug(
                state: state,
                environment: environment,
                message: "requestDeleteEntry should be handled by parent component"
            )
        case .entryDeleted(let slug):
            return entryDeleted(
                state: state,
                environment: environment,
                slug: slug
            )
        case .selectBacklink(let link):
            return update(
                state: state,
                action: .loadAndPresentDetail(
                    slug: link.slug,
                    fallback: link.linkableTitle,
                    autofocus: false
                ),
                environment: environment
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
        case .refreshLists:
            return refreshLists(
                state: state,
                environment: environment
            )
        }
    }

    /// Log debug
    static func log(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel> {
        environment.logger.log("\(message)")
        return Update(state: state)
    }

    /// Log debug
    static func logDebug(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel> {
        environment.logger.debug("\(message)")
        return Update(state: state)
    }

    /// Log debug
    static func logWarning(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel> {
        environment.logger.warning("\(message)")
        return Update(state: state)
    }

    /// Disambiguate URL opens and forward to specialized action types
    static func openURL(
        state: DetailModel,
        environment: AppEnvironment,
        url: URL
    ) -> Update<DetailModel> {
        // If link is not a sub:// link, then open it in browser
        guard SubURL.isSubEntryURL(url) else {
            return update(
                state: state,
                action: .openBrowserURL(url),
                environment: environment
            )
        }
        return update(
            state: state,
            action: .openEditorURL(url),
            environment: environment
        )
    }

    /// Open URL in browser
    /// Request open URL in editor
    static func openBrowserURL(
        state: DetailModel,
        environment: AppEnvironment,
        url: URL
    ) -> Update<DetailModel> {
        /// Open in browser
        UIApplication.shared.open(url)
        return Update(state: state)
    }

    /// Request open URL in editor
    static func openEditorURL(
        state: DetailModel,
        environment: AppEnvironment,
        url: URL
    ) -> Update<DetailModel> {
        // Otherwise decode link from URL and request detail
        let link = EntryLink.decodefromSubEntryURL(url)
        return update(
            state: state,
            action: .loadAndPresentDetail(
                slug: link?.slug,
                fallback: link?.title ?? "",
                autofocus: false
            ),
            environment: environment
        )
    }

    /// Set the contents of the editor and mark save state and modified time.
    static func setEditor(
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        saveState: SaveState,
        modified: Date
    ) -> Update<DetailModel> {
        var model = state
        model.saveState = saveState
        model.modified = modified
        return update(
            state: model,
            action: .markupEditor(.setText(text)),
            environment: environment
        )
    }

    /// Handle editor focus request.
    /// Saves editor state if blurred.
    static func editorFocusChange(
        state: DetailModel,
        environment: AppEnvironment,
        isFocused: Bool
    ) -> Update<DetailModel> {
        // If blur, then send focus request down and save
        guard isFocused else {
            return update(
                state: state,
                actions: [
                    .markupEditor(.focusChange(false)),
                    .autosave
                ],
                environment: environment
            )
        }
        // Otherwise, just send down focus request
        return update(
            state: state,
            action: .markupEditor(.focusChange(true)),
            environment: environment
        )
    }

    /// Set editor selection.
    static func setEditorSelection(
        state: DetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        text: String
    ) -> Update<DetailModel> {
        // Set entry link based on selection
        let dom = Subtext.parse(markup: text)
        let link = dom.entryLinkFor(range: nsRange)
        var model = state
        model.selectedEntryLinkMarkup = link

        let linkSearchText = link?.toTitle() ?? ""

        return DetailModel.update(
            state: model,
            actions: [
                // Immediately send down setSelection
                DetailAction.markupEditor(
                    MarkupTextAction.setSelection(range: nsRange, text: text)
                ),
                DetailAction.setLinkSearch(linkSearchText)
            ],
            environment: environment
        )
    }

    /// Set text cursor at end of editor
    static func setEditorSelectionEnd(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        let range = NSRange(
            state.markupEditor.text.endIndex...,
            in: state.markupEditor.text
        )

        return setEditorSelection(
            state: state,
            environment: environment,
            range: range,
            text: state.markupEditor.text
        )
    }

    /// Insert text in editor at range
    static func insertEditorText(
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<DetailModel> {
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

        // Set editor dom and editor selection immediately in same Update.
        return DetailModel.update(
            state: state,
            actions: [
                .setEditor(
                    text: markup,
                    saveState: .modified,
                    modified: .now
                ),
                .setEditorSelection(
                    range: NSRange(cursor..<cursor, in: markup),
                    text: markup
                )
            ],
            environment: environment
        )
    }

    /// Toggle detail presentation
    static func presentDetail(
        state: DetailModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<DetailModel> {
        var model = state
        model.isPresented = isPresented
        return Update(state: model)
    }

    /// Mark properties on model in preparation for detail load
    static func prepareLoadDetail(_ state: DetailModel) -> DetailModel {
        var model = state
        // Mark loading state
        model.isLoading = true
        // Mark time of load start
        model.lastLoadStarted = Date.now
        return model
    }

    /// Load Detail from database and present detail
    static func loadAndPresentDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    ) -> Update<DetailModel> {
        guard let slug = slug else {
            environment.logger.log(
                "Load and present detail requested, but nothing was being edited. Skipping."
            )
            return Update(state: state)
        }

        let fx: Fx<DetailAction> = environment.database
            .readEntryDetail(
                slug: slug,
                fallback: fallback
            )
            .map({ detail in
                DetailAction.setAndPresentDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(DetailAction.failLoadDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        let model = prepareLoadDetail(state)
        return Update(state: model, fx: fx)
    }

    /// Reload detail
    static func refreshDetail(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        guard let slug = state.slug else {
            environment.logger.log(
                "Refresh detail requested when nothing was being edited. Skipping."
            )
            return Update(state: state)
        }

        let model = prepareLoadDetail(state)

        let fx: Fx<DetailAction> = environment.database
            .readEntryDetail(
                slug: slug,
                fallback: model.markupEditor.text
            )
            .map({ detail in
                DetailAction.setDetailLastWriteWins(detail)
            })
            .catch({ error in
                Just(DetailAction.failLoadDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }

    static func refreshDetailIfStale(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        guard let slug = state.slug else {
            environment.logger.debug(
                "Refresh-detail-if-stale requested, but nothing was being edited. Skipping."
            )
            return Update(state: state)
        }
        let lastLoadElapsed = Date.now.timeIntervalSince(state.lastLoadStarted)
        guard lastLoadElapsed > state.loadStaleInterval else {
            environment.logger.debug(
                "Detail is fresh. No refresh needed. Skipping."
            )
            return Update(state: state)
        }
        environment.logger.log(
            "Detail for \(slug) is stale. Refreshing."
        )
        return update(
            state: state,
            action: .refreshDetail,
            environment: environment
        )
    }

    /// Handle detail load failure
    static func failLoadDetail(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel> {
        environment.logger.log("Detail load failed with message: \(message)")
        return Update(state: state)
    }

    /// Set EntryDetail onto DetailModel
    static func forceSetDetail(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail
    ) -> Update<DetailModel> {
        let modified = detail.entry.modified()
        var model = state
        model.isLoading = false
        model.modified = modified
        model.slug = detail.slug
        model.headers = detail.entry.headers
        model.backlinks = detail.backlinks
        model.saveState = detail.saveState

        return DetailModel.update(
            state: model,
            action: .setEditor(
                text: detail.entry.body,
                saveState: detail.saveState,
                modified: detail.entry.modified()
            ),
            environment: environment
        )
    }

    /// Set detail model.
    /// - If details slugs are the same, uses a last-write-wins strategy
    ///   for reconciling conflicts.
    /// - If details are different, saves the previous detail and
    ///   replaces it.
    static func setDetailLastWriteWins(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail
    ) -> Update<DetailModel> {
        var model = state
        // Mark loading finished
        model.isLoading = false

        let change = FileFingerprintChange.create(
            left: FileFingerprint(state),
            right: FileFingerprint(detail)
        )
        // Last write wins strategy
        switch change {
        // Our editor state is newer. Do nothing.
        case .leftNewer:
            return Update(state: model)
        // The slugs are same, but loaded detail is newer. Replace.
        case .rightNewer:
            return update(
                state: model,
                action: .forceSetDetail(detail),
                environment: environment
            )
        // No loaded detail. Do nothing.
        case .leftOnly:
            return Update(state: model)
        // No entry is currently being edited. Replace.
        case .rightOnly:
            return update(
                state: state,
                action: .forceSetDetail(detail),
                environment: environment
            )
        // Same slug, same time, different sizes. Conflict. Do nothing.
        case .conflict:
            return Update(state: model)
        // No change. Do nothing.
        case .same:
            return Update(state: model)
        // Slugs don't match. Different entries.
        // Save current state and set new detail.
        case .none:
            let snapshot = SubtextFile(model)
            return update(
                state: model,
                actions: [
                    .save(snapshot),
                    .forceSetDetail(detail)
                ],
                environment: environment
            )
        }
    }

    /// Set and present detail
    static func setAndPresentDetail(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail,
        autofocus: Bool
    ) -> Update<DetailModel> {
        update(
            state: state,
            actions: [
                .presentDetail(true),
                .setDetailLastWriteWins(detail),
                .editorFocusChange(autofocus)
            ],
            environment: environment
        )
    }

    /// Request detail view for entry.
    /// Fall back on contents of template file when no detail
    /// exists for this slug yet.
    static func loadAndPresentTemplateDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug,
        template: Slug,
        autofocus: Bool
    ) -> Update<DetailModel> {
        let fx: Fx<DetailAction> = environment.database
            .readEntryDetail(slug: slug, template: template)
            .map({ detail in
                DetailAction.setAndPresentDetail(
                    detail: detail,
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(DetailAction.failLoadDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        let model = prepareLoadDetail(state)
        return Update(state: model, fx: fx)
    }

    /// Request detail for a random entry
    static func loadAndPresentRandomDetail(
        state: DetailModel,
        environment: AppEnvironment,
        autofocus: Bool
    ) -> Update<DetailModel> {
        let fx: Fx<DetailAction> = environment.database.readRandomEntrySlug()
            .map({ slug in
                DetailAction.loadAndPresentDetail(
                    slug: slug,
                    fallback: slug.toTitle(),
                    autofocus: autofocus
                )
            })
            .catch({ error in
                Just(DetailAction.failLoadDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Reset model to "none" condition
    static func resetDetail(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        var model = state
        model.slug = nil
        model.modified = Date.distantPast
        model.headers = HeaderIndex()
        model.markupEditor = MarkupTextModel()
        model.backlinks = []
        model.isLoading = true
        model.saveState = .saved
        return Update(state: state)
    }

    static func autosave(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        environment.logger.debug(
            "Saved entry: \(entry.slug)"
        )
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

        return Update(state: model)
    }

    static func failSave(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug,
        message: String
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        var model = state
        model.isLinkSheetPresented = isPresented
        return Update(state: model)
    }

    static func setLinkSearch(
        state: DetailModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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

        return DetailModel.update(
            state: model,
            actions: [
                .setLinkSheetPresented(false),
                .insertEditorText(text: replacement, range: range)
            ],
            environment: environment
        )
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }

    /// Show rename sheet.
    /// Do rename-flow-related setup.
    static func showRenameSheet(
        state: DetailModel,
        environment: AppEnvironment,
        entry: EntryLink?
    ) -> Update<DetailModel> {
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

        return DetailModel.update(
            state: model,
            actions: [
                .autosave,
                .setRenameField(title)
            ],
            environment: environment
        )
    }

    /// Hide rename sheet.
    /// Do rename-flow-related teardown.
    static func hideRenameSheet(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        var model = state
        model.isRenameSheetShowing = false
        model.entryToRename = nil

        return DetailModel.update(
            state: model,
            action: .setRenameField(""),
            environment: environment
        )
    }

    /// Set text of slug field
    static func setRenameField(
        state: DetailModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        return update(
            state: state,
            actions: [
                .loadAndPresentDetail(
                    slug: to.slug,
                    fallback: to.linkableTitle,
                    autofocus: false
                ),
                .refreshLists
            ],
            environment: environment
        )
    }

    /// Move failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMoveEntry(
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        return update(
            state: state,
            actions: [
                .loadAndPresentDetail(
                    slug: parent.slug,
                    fallback: parent.linkableTitle,
                    autofocus: false
                ),
                // Refresh list views since old entry no longer exists
                .refreshLists
            ],
            environment: environment
        )
    }

    /// Merge failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMergeEntry(
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        /// We succeeded in updating title header on disk.
        /// Now set it in the view, so we see the updated state.
        var model = state
        model.headers["title"] = to.linkableTitle

        return update(
            state: state,
            action: .refreshLists,
            environment: environment
        )
    }

    /// Retitle failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failRetitleEntry(
        state: DetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<DetailModel> {
        environment.logger.warning(
            "Failed to retitle entry with error: \(error)"
        )
        return Update(state: state)
    }

    /// Show/hide entry delete confirmation dialog.
    static func presentDeleteConfirmationDialog(
        state: DetailModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<DetailModel> {
        var model = state
        model.isDeleteConfirmationDialogShowing = isPresented
        return Update(state: model)
            .animation(.default)
    }

    static func entryDeleted(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<DetailModel> {
        guard state.slug == slug else {
            // If entry that was deleted was not this entry, then just
            // refresh lists.
            return update(
                state: state,
                action: .refreshLists,
                environment: environment
            )
        }

        // If the slug currently being edited was just deleted,
        // - reset the editor
        // - un-present detail
        return DetailModel.update(
            state: state,
            actions: [
                .resetDetail,
                .refreshLists,
                .presentDetail(false)
            ],
            environment: environment
        )
    }

    /// Insert wikilink markup into editor, begining at previous range
    /// and wrapping the contents of previous range
    static func insertTaggedMarkup<T>(
        state: DetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        with withMarkup: (String) -> T
    ) -> Update<DetailModel>
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

        return DetailModel.update(
            state: state,
            actions: [
                .setEditor(
                    text: editorText,
                    saveState: .modified,
                    modified: .now
                ),
                .setEditorSelection(
                    range: NSRange(cursor..<cursor, in: editorText),
                    text: editorText
                )
            ],
            environment: environment
        )
    }

    /// Dispatch refresh actions
    static func refreshLists(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        return DetailModel.update(
            state: state,
            actions: [
                .refreshRenameSuggestions,
                .refreshLinkSuggestions
            ],
            environment: environment
        )
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

extension FileFingerprint {
    /// Initialize FileFingerprint from DetailModel.
    /// We use this to do last-write-wins.
    init?(_ detail: DetailModel) {
        guard let slug = detail.slug else {
            return nil
        }
        self.init(
            slug: slug,
            modified: detail.modified,
            text: detail.markupEditor.text
        )
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

    var store: ViewStore<DetailModel>

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
                                    store: ViewStore(
                                        store: store,
                                        cursor: DetailMarkupEditorCursor.self
                                    ),
                                    frame: geometry.frame(in: .local),
                                    renderAttributesOf: Subtext.renderAttributesOf,
                                    onLink: { url, _, _, _ in
                                        store.send(.openURL(url))
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
                            isSheetPresented: Binding(
                                store: store,
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
        .onAppear {
            // When an editor is presented, refresh if stale.
            // This covers the case where the editor might have been in the
            // background for a while, and the content changed in another tab.
            store.send(.refreshDetailIfStale)
        }
        /// Catch link taps and handle them here
        .environment(\.openURL, OpenURLAction { url in
            store.send(.openURL(url))
            return .handled
        })
        .sheet(
            isPresented: Binding(
                store: store,
                get: \.isLinkSheetPresented,
                tag: DetailAction.setLinkSheetPresented
            )
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                suggestions: store.state.linkSuggestions,
                text: Binding(
                    store: store,
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
            isPresented: Binding(
                store: store,
                get: \.isRenameSheetShowing,
                tag: { _ in DetailAction.hideRenameSheet }
            )
        ) {
            RenameSearchView(
                current: EntryLink(store.state),
                suggestions: store.state.renameSuggestions,
                text: Binding(
                    store: store,
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
        .confirmationDialog(
            "Are you sure?",
            isPresented: Binding(
                store: store,
                get: \.isDeleteConfirmationDialogShowing,
                tag: DetailAction.showDeleteConfirmationDialog
            )
        ) {
            Button(
                role: .destructive,
                action: {
                    store.send(.requestDeleteEntry(store.state.slug))
                }
            ) {
                Text("Delete Immediately")
            }
        }
        .toolbar {
            DetailToolbarContent(
                link: EntryLink(store.state),
                onRename: {
                    store.send(.showRenameSheet(EntryLink(store.state)))
                },
                onDelete: {
                    store.send(.showDeleteConfirmationDialog(true))
                }
            )
        }
    }
}
