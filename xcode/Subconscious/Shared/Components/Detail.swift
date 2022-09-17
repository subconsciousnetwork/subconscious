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

    /// View did appear
    case didAppear
    /// View did disappear
    case didDisappear

    /// Link was tapped (disambiguates to browser or editor action)
    case openURL(URL)
    case openBrowserURL(URL)
    case openEditorURL(URL)
    /// Invokes save and blurs editor
    case selectDoneEditing


    // Detail
    /// Load detail
    case loadDetail(
        slug: Slug?,
        fallback: String
    )

    /// Unable to load detail
    case failLoadDetail(String)

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
    /// Show detail panel
    case presentDetail(Bool)
    /// Update entry being displayed
    case updateDetail(detail: EntryDetail, autofocus: Bool)
    /// Set detail to initial conditions
    case resetDetail
    /// Set entry detail
    case setDetail(EntryDetail)
    /// Set EntryDetail on DetailModel, but only if last modification happened
    /// more recently than DetailModel.
    case setDetailLastWriteWins(EntryDetail)

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
    case refreshAll

    static func requestEditorFocus(_ isFocused: Bool) -> Self {
        .markupEditor(.requestFocus(isFocused))
    }

    /// Select a link completion
    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
    }

    /// Generate a detail request from a suggestion
    static func fromSuggestion(_ suggestion: Suggestion) -> Self {
        switch suggestion {
        case .entry(let entryLink):
            return .requestDetail(
                slug: entryLink.slug,
                fallback: entryLink.linkableTitle,
                autofocus: false
            )
        case .search(let entryLink):
            return .requestDetail(
                slug: entryLink.slug,
                fallback: entryLink.linkableTitle,
                autofocus: true
            )
        case .journal(let entryLink):
            return .requestTemplateDetail(
                slug: entryLink.slug,
                template: Config.default.journalTemplate,
                // Autofocus note because we're creating it from scratch
                autofocus: true
            )
        case .scratch(let entryLink):
            return .requestDetail(
                slug: entryLink.slug,
                fallback: entryLink.linkableTitle,
                autofocus: true
            )
        case .random:
            return .requestRandomDetail(autofocus: false)
        }
    }

    var logDescription: String {
        switch self {
        case .setLinkSuggestions(let suggestions):
            return "setLinkSuggestions(\(suggestions.count) items)"
        case .setRenameSuggestions(let suggestions):
            return "setRenameSuggestions(\(suggestions.count) items)"
        case .markupEditor(let action):
            return "markupEditor(\(String.loggable(action)))"
        case .save(let entry):
            let slugString: String = entry.mapOr(
                { entry in String(entry.slug) },
                default: "nil"
            )
            return "save(\(slugString))"
        case .succeedSave(let entry):
            return "succeedSave(\(entry.slug))"
        case .updateDetail(let detail, _):
            return "updateDetail(\(detail.slug))"
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
    var modified = Date.now

    /// Is editor sliding panel showing?
    var isPresented = false
    /// Is view being displayed
    var isAppearing = false
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
        case .didAppear:
            return didAppear(
                state: state,
                environment: environment
            )
        case .didDisappear:
            return didDisappear(
                state: state,
                environment: environment
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
        case .selectDoneEditing:
            return selectDoneEditing(
                state: state,
                environment: environment
            )
        case .presentDetail(let isPresented):
            return presentDetail(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case let .loadDetail(slug, fallback):
            return loadDetail(
                state: state,
                environment: environment,
                slug: slug,
                fallback: fallback
            )
        case let .failLoadDetail(message):
            return log(
                state: state,
                environment: environment,
                message: message
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
        case .setDetailLastWriteWins(let detail):
            return setDetailLastWriteWins(
                state: state,
                environment: environment,
                detail: detail
            )
        case .setDetail(let detail):
            return setDetail(
                state: state,
                environment: environment,
                detail: detail
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
            return requestDetail(
                state: state,
                environment: environment,
                slug: link.slug,
                fallback: link.linkableTitle,
                autofocus: false
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

    /// Set view appear state
    /// We use onAppear/onDisappear to determine whether this detail
    /// is currently active for the purpose of refreshing state from disk.
    static func didAppear(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        var model = state
        model.isAppearing = true
        return Update(state: model)
    }

    /// Set view disappear state
    /// We use onAppear/onDisappear to determine whether this detail
    /// is currently active for the purpose of refreshing state from disk.
    static func didDisappear(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        var model = state
        model.isAppearing = false
        return Update(state: model)
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
            action: .requestDetail(
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

    /// Unfocus editor and save current state
    static func selectDoneEditing(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        return DetailModel.update(
            state: state,
            actions: [
                .requestEditorFocus(false),
                .autosave
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

    /// Factors out the non-get-detail related aspects
    /// of requesting a detail view.
    /// Used by a few request detail implementations.
    private static func prepareRequestDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<DetailModel> {
        var model = state
        model.isLoading = true
        return autosave(state: model, environment: environment)
    }

    /// Load Detail from database
    static func loadDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String
    ) -> Update<DetailModel> {
        guard let slug = slug else {
            environment.logger.log(
                ".loadDetail called with nil slug. Doing nothing."
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
                DetailAction.setDetailLastWriteWins(detail)
            })
            .catch({ error in
                Just(DetailAction.failLoadDetail(error.localizedDescription))
            })
            .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    static func setDetailLastWriteWins(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail
    ) -> Update<DetailModel> {
        let change = FileFingerprintChange.create(
            left: FileFingerprint(state),
            right: FileFingerprint(detail)
        )
        // Last write wins strategy
        switch change {
        case .rightNewer:
            return update(
                state: state,
                action: .setDetail(detail),
                environment: environment
            )
        case .rightOnly:
            return update(
                state: state,
                action: .setDetail(detail),
                environment: environment
            )
        // Our editor state is newer. Do nothing.
        case .leftNewer:
            return Update(state: state)
        // Somehow righthand FileFingerprint was nil. Do nothing.
        case .leftOnly:
            return Update(state: state)
        // Same. Do nothing.
        case .same:
            return Update(state: state)
        // Same time, different sizes
        case .conflict:
            return Update(state: state)
        /// Slugs don't match. Do nothing
        case .none:
            return Update(state: state)
        }
    }

    /// Set EntryDetail onto DetailModel
    static func setDetail(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail
    ) -> Update<DetailModel> {
        var modified = detail.entry.modified()
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

    /// Request detail view for entry.
    /// Fall back on string (typically query string) when no detail
    /// exists for this slug yet.
    static func requestDetail(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug?,
        fallback: String,
        autofocus: Bool
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        return DetailModel.update(
            state: state,
            actions: [
                .refreshAll,
                .requestDetail(
                    slug: slug,
                    fallback: "",
                    autofocus: false
                )
            ],
            environment: environment
        )
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
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
    ) -> Update<DetailModel> {
        // If we just loaded the detail we're already editing, do not
        // blow it away. Just mark loading complete and show detail.
        // The in-memory version we are editing should win.
        guard state.slug != detail.slug else {
            environment.logger.log(
                "Entry already being edited. Using in-memory version."
            )
            var model = state
            model.isLoading = false
            return update(
                state: model,
                action: .presentDetail(true),
                environment: environment
            )
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
        model.saveState = detail.saveState

        // If editor is not meant to be focused, return early, setting focus
        // to nil.
        guard autofocus else {
            return DetailModel.update(
                state: model,
                actions: [
                    .setEditor(
                        text: detail.entry.body,
                        saveState: detail.saveState,
                        modified: detail.entry.modified()
                    ),
                    .presentDetail(true),
                    .requestEditorFocus(false)
                ],
                environment: environment
            )
            .mergeFx(saveFx)
        }

        // Otherwise, set editor selection and focus to end of document.
        // When you've just created a new note, chances are you want to
        // edit it, not browse it.
        // We focus the editor and place the cursor at the end so you can just
        // start typing
        return DetailModel.update(
            state: model,
            actions: [
                .setEditor(
                    text: detail.entry.body,
                    saveState: detail.saveState,
                    modified: detail.entry.modified()
                ),
                .presentDetail(true),
                .setEditorSelectionEnd,
                .requestEditorFocus(true)
            ],
            environment: environment
        )
        .mergeFx(saveFx)
    }

    /// Reset model to "none" condition
    static func resetDetail(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
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

        return update(
            state: model,
            action: .refreshAll,
            environment: environment
        )
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
            actions: [
                .refreshLinkSuggestions,
                .refreshRenameSuggestions
            ],
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
        // If entry that was deleted was not this entry, then we don't
        // have to do anything.
        guard state.slug == slug else {
            return Update(state: state)
        }

        // If the slug currently being edited was just deleted,
        // - reset the editor
        // - un-present detail
        return DetailModel.update(
            state: state,
            actions: [
                .resetDetail,
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
    static func refreshAll(
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
            store.send(.didAppear)
        }
        .onDisappear {
            store.send(.didDisappear)
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
