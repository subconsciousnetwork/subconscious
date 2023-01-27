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

//  MARK: View
struct DetailView: View {
    /// Detail keeps a separate internal store for editor state that does not
    /// need to be surfaced in higher level views.
    ///
    /// This gives us a pretty big efficiency win, since keystrokes will only
    /// rerender this view, and not whole app view tree.
    @StateObject private var store = Store(
        state: DetailModel(),
        action: .start,
        environment: AppEnvironment.default
    )
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    /// State passed down from parent
    var state: DetailOuterModel
    var send: (DetailOuterAction) -> Void

    var body: some View {
        VStack {
            if store.state.slug != nil {
                DetailReadyView(
                    store: store,
                    state: state,
                    send: send
                )
            } else {
                VStack {
                    Spacer()
                    Text("Nothing here")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle(state.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DetailToolbarContent(
                link: EntryLink(slug: state.slug, title: state.title),
                onRename: {
                    store.send(
                        .showRenameSheet(
                            EntryLink(slug: state.slug, title: state.title)
                        )
                    )
                },
                onDelete: {
                    store.send(.presentDeleteConfirmationDialog(true))
                }
            )
        }
        .onAppear {
            // When an editor is presented, refresh if stale.
            // This covers the case where the editor might have been in the
            // background for a while, and the content changed in another tab.
            store.send(
                DetailAction.appear(
                    slug: state.slug,
                    title: state.title,
                    fallback: state.fallback
                )
            )
        }
        .onDisappear {
            store.send(.autosave)
        }
        /// Catch link taps and handle them here
        .environment(\.openURL, OpenURLAction { url in
            guard let link = EntryLink.decodefromSubEntryURL(url) else {
                return .systemAction
            }
            send(
                .requestDetail(
                    slug: link.slug,
                    title: link.linkableTitle,
                    fallback: link.title
                )
            )
            return .handled
        })
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(DetailAction.scenePhaseChange(phase))
        }
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            DetailModel.logger.debug("[action] \(message)")
        }
        // Filtermap actions to outer actions, and forward them to parent
        .onReceive(
            store.actions.compactMap(DetailOuterAction.from)
        ) { action in
            send(action)
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isLinkSheetPresented },
                send: store.send,
                tag: DetailAction.setLinkSheetPresented
            )
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                suggestions: store.state.linkSuggestions,
                text: Binding(
                    get: { store.state.linkSearchText },
                    send: store.send,
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
                get: { store.state.isRenameSheetShowing },
                send: store.send,
                tag: { _ in DetailAction.hideRenameSheet }
            )
        ) {
            RenameSearchView(
                current: EntryLink(store.state),
                suggestions: store.state.renameSuggestions,
                text: Binding(
                    get: { store.state.renameField },
                    send: store.send,
                    tag: DetailAction.setRenameField
                ),
                onCancel: {
                    store.send(.hideRenameSheet)
                },
                onSelect: { suggestion in
                    store.send(DetailAction.from(suggestion))
                }
            )
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: Binding(
                get: { store.state.isDeleteConfirmationDialogShowing },
                send: store.send,
                tag: DetailAction.presentDeleteConfirmationDialog
            )
        ) {
            Button(
                role: .destructive,
                action: {
                    send(.requestDelete(state.slug))
                }
            ) {
                Text("Delete Immediately")
            }
        }
    }
}

struct DetailReadyView: View {
    @ObservedObject var store: Store<DetailModel>
    @Environment(\.scenePhase) var scenePhase: ScenePhase
    var state: DetailOuterModel
    var send: (DetailOuterAction) -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Divider()
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        MarkupTextViewRepresentable(
                            state: store.state.markupEditor,
                            send: Address.forward(
                                send: store.send,
                                tag: DetailMarkupEditorCursor.tag
                            ),
                            frame: geometry.frame(in: .local),
                            renderAttributesOf: Subtext.renderAttributesOf,
                            onLink: { url, _, _, _ in
                                guard let link = EntryLink.decodefromSubEntryURL(url) else {
                                    return true
                                }
                                send(
                                    .requestDetail(
                                        slug: link.slug,
                                        title: link.linkableTitle,
                                        fallback: link.title
                                    )
                                )
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
                            minHeight: UIFont.appTextMono.lineHeight * 8

                        )
                        ThickDividerView()
                            .padding(.bottom, AppTheme.unit4)
                        BacklinksView(
                            backlinks: store.state.backlinks,
                            onSelect: { link in
                                send(
                                    .requestDetail(
                                        slug: link.slug,
                                        title: link.linkableTitle,
                                        fallback: link.title
                                    )
                                )
                            }
                        )
                    }
                }
                if store.state.markupEditor.focus {
                    DetailKeyboardToolbarView(
                        isSheetPresented: Binding(
                            get: { store.state.isLinkSheetPresented },
                            send: store.send,
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
        }
    }
}

//  MARK: Action

/// Actions that are forwarded up to the parent component
enum DetailOuterAction: Hashable {
    case requestDetail(slug: Slug, title: String, fallback: String)
    case requestDelete(Slug?)
    case succeedMoveEntry(from: EntryLink, to: EntryLink)
    case succeedMergeEntry(parent: EntryLink, child: EntryLink)
    case succeedRetitleEntry(from: EntryLink, to: EntryLink)
    case succeedSaveEntry(slug: Slug, modified: Date)
}

extension DetailOuterAction {
    static func from(_ action: DetailAction) -> Self? {
        switch action {
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedRetitleEntry(from, to):
            return .succeedRetitleEntry(from: from, to: to)
        case let .succeedSave(entry):
            return .succeedSaveEntry(
                slug: entry.slug,
                modified: entry.contents.modified
            )
        default:
            return nil
        }
    }
}

/// Actions handled by detail's private store.
enum DetailAction: Hashable, CustomLogStringConvertible {
    /// Sent once and only once on Store initialization
    case start

    /// When scene phase changes.
    /// E.g. when app is foregrounded, backgrounded, etc.
    case scenePhaseChange(ScenePhase)

    /// Wrapper for editor actions
    case markupEditor(MarkupTextAction)

    case appear(
        slug: Slug?,
        title: String,
        fallback: String,
        autofocus: Bool = false
    )

    // Detail
    /// Load detail, using a last-write-wins strategy for replacement
    /// if detail is already loaded.
    case loadDetail(
        link: EntryLink?,
        fallback: String,
        autofocus: Bool
    )
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
    /// Set detail
    case setDetail(detail: EntryDetail, autofocus: Bool)
    /// Set detail to initial conditions
    case resetDetail

    //  Saving entry
    /// Trigger autosave of current state
    case autosave
    /// Save an entry at a particular snapshot value
    case save(MemoEntry?)
    case succeedSave(MemoEntry)
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

    // Rename entry
    /// Move an entry from one location to another
    case moveEntry(from: EntryLink, to: EntryLink)
    /// Move entry succeeded. Lifecycle action.
    case succeedMoveEntry(from: EntryLink, to: EntryLink)
    /// Move entry failed. Lifecycle action.
    case failMoveEntry(String)
    /// Merge entries
    case mergeEntry(parent: EntryLink, child: EntryLink)
    /// Merge entry succeeded. Lifecycle action.
    case succeedMergeEntry(parent: EntryLink, child: EntryLink)
    /// Merge entry failed. Lifecycle action.
    case failMergeEntry(String)
    /// Retitle an entry (change its title header)
    case retitleEntry(from: EntryLink, to: EntryLink)
    /// Retitle entry succeeded. Lifecycle action.
    case succeedRetitleEntry(from: EntryLink, to: EntryLink)
    /// Retitle entry failed. Lifecycle action.
    case failRetitleEntry(String)

    //  Delete entry requests
    /// Show/hide delete confirmation dialog
    case presentDeleteConfirmationDialog(Bool)

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

    /// Local action for requesting editor focus.
    static func requestEditorFocus(_ focus: Bool) -> Self {
        .markupEditor(.requestFocus(focus))
    }

    static var setEditorSelectionAtEnd: Self {
        .markupEditor(.setSelectionAtEnd)
    }

    /// Synonym for requesting editor blur.
    static var selectDoneEditing: Self {
        .markupEditor(.requestFocus(false))
    }

    /// Select a link completion
    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
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
        case let .forceSetDetail(detail):
            return "forceSetDetail(\(String.loggable(detail)))"
        case .save(let entry):
            let slugString: String = entry.mapOr(
                { entry in String(entry.slug) },
                default: "nil"
            )
            return "save(\(slugString))"
        case .succeedSave(let entry):
            return "succeedSave(\(entry.slug))"
        case .setDetail(let detail, _):
            return "setDetail(\(String.loggable(detail)))"
        case let .setEditor(_, saveState, modified):
            return "setEditor(text: ..., saveState: \(String(describing: saveState)), modified: \(modified))"
        case let .setEditorSelection(range, _):
            return "setEditorSelection(range: \(range), text: ...)"
        default:
            return String(describing: self)
        }
    }
}

extension DetailAction {
    static func from(_ suggestion: RenameSuggestion) -> Self {
        switch suggestion {
        case let .move(from, to):
            return .moveEntry(from: from, to: to)
        case let .merge(parent, child):
            return .mergeEntry(parent: parent, child: child)
        case let .retitle(from, to):
            return .retitleEntry(from: from, to: to)
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
        // Intercept focusChange, so we can save on blur.
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
    /// Required headers
    /// Initialize date with Unix Epoch
    var headers = WellKnownHeaders(
        contentType: ContentType.subtext.rawValue,
        created: Date.distantPast,
        modified: Date.distantPast,
        title: "",
        fileExtension: ContentType.subtext.fileExtension
    )
    /// Additional headers that are not well-known headers.
    var additionalHeaders: Headers = []
    var backlinks: [EntryStub] = []
    
    /// Is editor saved?
    var saveState = SaveState.saved

    /// Is editor in loading state?
    var isLoading = true
    /// When was the last time the editor issued a fetch from source of truth?
    var lastLoadStarted = Date.distantPast

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

    /// Time interval after which a load is considered stale, and should be
    /// reloaded to make sure it is fresh.
    static let loadStaleInterval: TimeInterval = 0.2

    /// Given a particular entry value, does the editor's state
    /// currently match it, such that we could say the editor is
    /// displaying that entry?
    func stateMatches(entry: MemoEntry) -> Bool {
        guard let slug = self.slug else {
            return false
        }
        return (
            slug == entry.slug &&
            markupEditor.text == entry.contents.body.description
        )
    }

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "detail"
    )

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
        case .start:
            return start(
                state: state,
                environment: environment
            )
        case .scenePhaseChange(let phase):
            return scenePhaseChange(
                state: state,
                environment: environment,
                phase: phase
            )
        case let .appear(slug, title, fallback, autofocus):
            return appear(
                state: state,
                environment: environment,
                slug: slug,
                title: title,
                fallback: fallback,
                autofocus: autofocus
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
        case let .insertEditorText(text, range):
            return insertEditorText(
                state: state,
                environment: environment,
                text: text,
                range: range
            )
        case let .loadDetail(link, fallback, autofocus):
            return loadDetail(
                state: state,
                environment: environment,
                link: link,
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
        case let .setDetail(detail, autofocus):
            return setDetail(
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
            logger.debug(
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
        case .moveEntry(let from, let to):
            return moveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case let .succeedMoveEntry(from, to):
            return succeedMoveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .failMoveEntry(let error):
            return failMoveEntry(
                state: state,
                environment: environment,
                error: error
            )
        case .mergeEntry(let parent, let child):
            return mergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case let .succeedMergeEntry(parent, child):
            return succeedMergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case .failMergeEntry(let error):
            return failMergeEntry(
                state: state,
                environment: environment,
                error: error
            )
        case .retitleEntry(let from, let to):
            return retitleEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case let .succeedRetitleEntry(from, to):
            return succeedRetitleEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .failRetitleEntry(let error):
            return failRetitleEntry(
                state: state,
                environment: environment,
                error: error
            )
        case .presentDeleteConfirmationDialog(let isPresented):
            return presentDeleteConfirmationDialog(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .selectBacklink(let link):
            return update(
                state: state,
                action: .loadDetail(
                    link: link,
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
        logger.log("\(message)")
        return Update(state: state)
    }

    /// Log debug
    static func logDebug(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel> {
        logger.debug("\(message)")
        return Update(state: state)
    }

    /// Log debug
    static func logWarning(
        state: DetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<DetailModel> {
        logger.warning("\(message)")
        return Update(state: state)
    }

    static func start(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        let pollFx = AppEnvironment.poll(every: Config.default.pollingInterval)
            .map({ _ in DetailAction.autosave })
            .eraseToAnyPublisher()
        return Update(state: state, fx: pollFx)
    }

    /// Handle scene phase change
    /// We trigger an autosave when scene becomes inactive.
    static func scenePhaseChange(
        state: DetailModel,
        environment: AppEnvironment,
        phase: ScenePhase
    ) -> Update<DetailModel> {
        switch phase {
        case .inactive:
            return update(
                state: state,
                action: .autosave,
                environment: environment
            )
        default:
            return Update(state: state)
        }
    }

    /// Set the contents of the editor and mark save state and modified time.
    static func appear(
        state: DetailModel,
        environment: AppEnvironment,
        slug: Slug?,
        title: String,
        fallback: String,
        autofocus: Bool
    ) -> Update<DetailModel> {
        let link = slug.map({ slug in EntryLink(slug: slug, title: title) })
        return update(
            state: state,
            action: .loadDetail(
                link: link,
                fallback: fallback,
                autofocus: autofocus
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
        model.headers.modified = modified
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

    /// Insert text in editor at range
    static func insertEditorText(
        state: DetailModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<DetailModel> {
        guard let range = Range(nsRange, in: state.markupEditor.text) else {
            logger.log(
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
            logger.log(
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
    static func loadDetail(
        state: DetailModel,
        environment: AppEnvironment,
        link: EntryLink?,
        fallback: String,
        autofocus: Bool
    ) -> Update<DetailModel> {
        guard let link = link else {
            logger.log(
                "Load and present detail requested, but nothing was being edited. Skipping."
            )
            return Update(state: state)
        }

        let fx: Fx<DetailAction> = environment.data
            .readEntryDetail(
                link: link,
                fallback: fallback
            )
            .map({ detail in
                DetailAction.setDetail(
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
            logger.log(
                "Refresh detail requested when nothing was being edited. Skipping."
            )
            return Update(state: state)
        }

        let model = prepareLoadDetail(state)

        let fx: Fx<DetailAction> = environment.data
            .readEntryDetail(
                link: EntryLink(slug: slug),
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
            logger.debug(
                "Refresh-detail-if-stale requested, but nothing was being edited. Skipping."
            )
            return Update(state: state)
        }
        let lastLoadElapsed = Date.now.timeIntervalSince(state.lastLoadStarted)
        guard lastLoadElapsed > Self.loadStaleInterval else {
            logger.debug(
                "Detail is fresh. No refresh needed. Skipping."
            )
            return Update(state: state)
        }
        logger.log(
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
        var model = state
        model.isLoading = false
        model.slug = detail.slug
        model.headers = detail.entry.contents.wellKnownHeaders()
        model.additionalHeaders = detail.entry.contents.additionalHeaders
        model.backlinks = detail.backlinks
        model.saveState = detail.saveState

        let subtext = detail.entry.contents.body
        let text = String(describing: subtext)

        return DetailModel.update(
            state: model,
            action: .setEditor(
                text: text,
                saveState: detail.saveState,
                modified: model.headers.modified
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
            let snapshot = MemoEntry(model)
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
    /// - state: the current state
    /// - environment: the environment
    /// - detail: the entry detail (usually we get this back from a service)
    /// - autofocus: automatically focus the editor,
    ///   and set cursor at end of document?
    /// - Returns: an update
    static func setDetail(
        state: DetailModel,
        environment: AppEnvironment,
        detail: EntryDetail,
        autofocus: Bool
    ) -> Update<DetailModel> {
        guard autofocus else {
            // If autofocus is false, request blur if needed
            return update(
                state: state,
                actions: [
                    .setDetailLastWriteWins(detail),
                    .requestEditorFocus(false)
                ],
                environment: environment
            )
        }
        // If autofocus is true, request focus, and also set selection to end
        // of editor text.
        return update(
            state: state,
            actions: [
                .setDetailLastWriteWins(detail),
                .requestEditorFocus(true),
                .setEditorSelectionAtEnd
            ],
            environment: environment
        )
    }

    /// Reset model to "none" condition
    static func resetDetail(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        var model = state
        model.slug = nil
        model.headers = WellKnownHeaders(
            contentType: ContentType.subtext.rawValue,
            created: Date.distantPast,
            modified: Date.distantPast,
            title: "",
            fileExtension: ContentType.subtext.fileExtension
        )
        model.additionalHeaders = []
        model.markupEditor = MarkupTextModel()
        model.backlinks = []
        model.isLoading = true
        model.saveState = .saved
        return Update(state: model)
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
        entry: MemoEntry?
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

        let fx: Fx<DetailAction> = environment.data
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
        entry: MemoEntry
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

        // Search link suggestions
        let fx: Fx<DetailAction> = environment.data
            .searchLinkSuggestions(
                query: text,
                omitting: omitting,
                fallback: []
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
        let fx: Fx<DetailAction> = environment.data
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

    /// Move entry
    static func moveEntry(
        state: DetailModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<DetailModel> {
        let fx: Fx<DetailAction> = environment.data
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
        return Update(
            state: state,
            fx: fx
        )
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
            actions: [.hideRenameSheet, .refreshLists],
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
        let fx: Fx<DetailAction> = environment.data
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
        return Update(state: state, fx: fx)
    }

    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: DetailModel,
        environment: AppEnvironment,
        parent: EntryLink,
        child: EntryLink
    ) -> Update<DetailModel> {
        var model = state
        model.slug = parent.slug
        model.headers.title = parent.linkableTitle
        return update(
            state: model,
            actions: [.refreshLists, .hideRenameSheet, .refreshDetail],
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
        let fx: Fx<DetailAction> = environment.data
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
        return Update(state: state, fx: fx)
    }

    /// Retitle success lifecycle handler.
    /// Updates UI in response.
    static func succeedRetitleEntry(
        state: DetailModel,
        environment: AppEnvironment,
        from: EntryLink,
        to: EntryLink
    ) -> Update<DetailModel> {
        return update(
            state: state,
            actions: [.refreshLists, .hideRenameSheet],
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
        logger.warning(
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
            logger.log(
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
            logger.log(
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
    func snapshotEntry() -> MemoEntry? {
        guard var entry = MemoEntry(self) else {
            return nil
        }
        entry.contents.modified = Date.now
        return entry
    }
}

//  MARK: Outer Model
/// A description of a detail suitible for pushing onto a navigation stack
struct DetailOuterModel: Hashable, ModelProtocol {
    var slug: Slug
    var title: String
    var fallback: String
    
    static func update(
        state: DetailOuterModel,
        action: DetailOuterAction,
        environment: AppEnvironment
    ) -> ObservableStore.Update<DetailOuterModel> {
        Update(state: state)
    }
}

extension EntryLink {
    init?(_ detail: DetailModel) {
        guard let slug = detail.slug else {
            return nil
        }
        self.init(slug: slug, title: detail.headers.title)
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
            modified: detail.headers.modified,
            text: detail.markupEditor.text
        )
    }
}

extension MemoEntry {
    init?(_ detail: DetailModel) {
        guard let slug = detail.slug else {
            return nil
        }
        self.slug = slug
        self.contents = Memo(
            contentType: detail.headers.contentType,
            created: detail.headers.created,
            modified: detail.headers.modified,
            title: detail.headers.title,
            fileExtension: detail.headers.fileExtension,
            additionalHeaders: detail.additionalHeaders,
            body: detail.markupEditor.text
        )
    }
}
