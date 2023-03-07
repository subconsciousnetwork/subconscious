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
    /// Is this view presented? Used to detect when back button is pressed.
    /// We trigger an autosave when isPresented is false below.
    @Environment(\.isPresented) var isPresented
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    /// State passed down from parent
    var state: DetailOuterModel
    var send: (DetailOuterAction) -> Void

    private func onLink(
        url: URL
    ) -> Bool {
        guard let link = UnqualifiedLink.decodefromSubEntryURL(
            url
        ) else {
            return true
        }
        send(
            .requestFindDetail(
                slug: link.slug,
                title: link.title,
                fallback: link.title
            )
        )
        return false
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        SubtextTextViewRepresentable(
                            state: store.state.editor,
                            send: Address.forward(
                                send: store.send,
                                tag: DetailEditorCursor.tag
                            ),
                            frame: geometry.frame(in: .local),
                            onLink: self.onLink
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
                                        address: link.address,
                                        title: link.linkableTitle,
                                        fallback: link.title
                                    )
                                )
                            }
                        )
                    }
                }
                if store.state.editor.focus {
                    DetailKeyboardToolbarView(
                        isSheetPresented: Binding(
                            get: { store.state.isLinkSheetPresented },
                            send: store.send,
                            tag: DetailAction.setLinkSheetPresented
                        ),
                        selectedShortlink: store.state.selectedShortlink,
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
                            store.send(.doneEditing)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible)
        .toolbarBackground(Color.background, for: .navigationBar)
        .toolbar(content: {
            DetailToolbarContent(
                address: store.state.address,
                defaultAudience: store.state.defaultAudience,
                onTapOmnibox: {
                    store.send(.presentMetaSheet(true))
                }
            )
        })
        .onAppear {
            // When an editor is presented, refresh if stale.
            // This covers the case where the editor might have been in the
            // background for a while, and the content changed in another tab.
            store.send(DetailAction.appear(state))
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(DetailAction.scenePhaseChange(phase))
        }
        // Save when back button pressed.
        // Note that .onDisappear is too late, because by the time the save
        // succeeds, the store for this view is already thrown away, so
        // we never receive the save-succeeded action.
        // Reacting to isPresented is soon enough.
        // 2023-02-14
        .onChange(of: self.isPresented) { isPresented in
            if !isPresented {
                store.send(.autosave)
            }
        }
        /// Catch link taps and handle them here
        .environment(\.openURL, OpenURLAction { url in
            guard let link = UnqualifiedLink.decodefromSubEntryURL(url) else {
                return .systemAction
            }
            send(
                .requestFindDetail(
                    slug: link.slug,
                    title: link.title,
                    fallback: link.title
                )
            )
            return .handled
        })
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
                get: { store.state.isMetaSheetPresented },
                send: store.send,
                tag: DetailAction.presentMetaSheet
            )
        ) {
            DetailMetaSheet(
                state: store.state.metaSheet,
                send: Address.forward(
                    send: store.send,
                    tag: DetailMetaSheetCursor.tag
                )
            )
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
    }
}

//  MARK: Action

/// Actions that are forwarded up to the parent component
enum DetailOuterAction: Hashable {
    /// Request specific detail
    case requestDetail(address: MemoAddress, title: String, fallback: String)
    /// Request detail from any audience scope
    case requestFindDetail(slug: Slug, title: String, fallback: String)
    case requestDelete(MemoAddress?)
    case succeedMoveEntry(from: MemoAddress, to: MemoAddress)
    case succeedMergeEntry(parent: MemoAddress, child: MemoAddress)
    case succeedSaveEntry(address: MemoAddress, modified: Date)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
}

extension DetailOuterAction {
    static func from(_ action: DetailAction) -> Self? {
        switch action {
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedSave(entry):
            return .succeedSaveEntry(
                address: entry.address,
                modified: entry.contents.modified
            )
        case .succeedUpdateAudience(let receipt):
            return .succeedUpdateAudience(receipt)
        default:
            return nil
        }
    }
}

/// Actions handled by detail's private store.
enum DetailAction: Hashable, CustomLogStringConvertible {
    /// Tagging action for detail meta bottom sheet
    case metaSheet(DetailMetaSheetAction)

    /// Sent once and only once on Store initialization
    case start

    /// When scene phase changes.
    /// E.g. when app is foregrounded, backgrounded, etc.
    case scenePhaseChange(ScenePhase)

    /// Wrapper for editor actions
    case editor(SubtextTextAction)

    case appear(DetailOuterModel)

    // Detail
    /// Load detail, using a last-write-wins strategy for replacement
    /// if detail is already loaded.
    case loadDetail(
        address: MemoAddress,
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
    case setDraftDetail(
        defaultAudience: Audience,
        fallback: String
    )
    /// Set detail to initial conditions
    case resetDetail

    // Change audience
    case updateAudience(_ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    case failUpdateAudience(_ message: String)

    // Finish with editing focus
    case doneEditing

    //  Saving entry
    /// Trigger autosave of current state
    case autosave
    /// Save an entry at a particular snapshot value
    case save(MemoEntry?)
    case succeedSave(MemoEntry)
    case failSave(
        address: MemoAddress,
        message: String
    )

    // Meta bottom sheet
    // Exposes controls for audience, rename, delete, etc.
    case presentMetaSheet(Bool)

    // Link suggestions
    case setLinkSheetPresented(Bool)
    case setLinkSearch(String)
    case refreshLinkSuggestions
    case selectLinkSuggestion(LinkSuggestion)
    case setLinkSuggestions([LinkSuggestion])
    case linkSuggestionsFailure(String)

    // Rename entry
    /// Intercepted rename action
    case selectRenameSuggestion(RenameSuggestion)
    /// Move an entry from one location to another
    case moveEntry(from: MemoAddress, to: MemoAddress)
    /// Move entry succeeded. Lifecycle action.
    case succeedMoveEntry(from: MemoAddress, to: MemoAddress)
    /// Move entry failed. Lifecycle action.
    case failMoveEntry(String)
    /// Merge entries
    case mergeEntry(parent: MemoAddress, child: MemoAddress)
    /// Merge entry succeeded. Lifecycle action.
    case succeedMergeEntry(parent: MemoAddress, child: MemoAddress)
    /// Merge entry failed. Lifecycle action.
    case failMergeEntry(String)

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
        .editor(.requestFocus(focus))
    }

    static var setEditorSelectionAtEnd: Self {
        .editor(.setSelectionAtEnd)
    }

    /// Select a link completion
    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
    }

    static var refreshRenameSuggestions: Self {
        .metaSheet(.refreshRenameSuggestions)
    }

    static func setMetaSheetAddress(_ address: MemoAddress?) -> Self {
        .metaSheet(.setAddress(address))
    }

    static func setMetaSheetDefaultAudience(_ audience: Audience) -> Self {
        .metaSheet(.setDefaultAudience(audience))
    }

    // MARK: logDescription
    var logDescription: String {
        switch self {
        case .setLinkSuggestions(let suggestions):
            return "setLinkSuggestions(\(suggestions.count) items)"
        case .editor(let action):
            return "editor(\(String.loggable(action)))"
        case let .setDetailLastWriteWins(detail):
            return "setDetailLastWriteWins(\(String.loggable(detail)))"
        case let .forceSetDetail(detail):
            return "forceSetDetail(\(String.loggable(detail)))"
        case .save(let entry):
            return "save(\(entry?.address.description ?? "nil"))"
        case .succeedSave(let entry):
            return "succeedSave(\(entry.address))"
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
        }
    }
}

//  MARK: Cursors
/// Editor cursor
struct DetailEditorCursor: CursorProtocol {
    static func get(state: DetailModel) -> SubtextTextModel {
        state.editor
    }

    static func set(
        state: DetailModel,
        inner: SubtextTextModel
    ) -> DetailModel {
        var model = state
        model.editor = inner
        return model
    }

    static func tag(_ action: SubtextTextAction) -> DetailAction {
        switch action {
        // Intercept text set action so we can mark all text-sets
        // as dirty.
        case .setText(let text):
            return .setEditor(
                text: text,
                saveState: .unsaved,
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
            return .editor(action)
        }
    }
}

struct DetailMetaSheetCursor: CursorProtocol {
    typealias Model = DetailModel
    typealias ViewModel = DetailMetaSheetModel

    static func get(state: Model) -> ViewModel {
        state.metaSheet
    }

    static func set(
        state: Model,
        inner: ViewModel
    ) -> Model {
        var model = state
        model.metaSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .selectRenameSuggestion(let suggestion):
            return .selectRenameSuggestion(suggestion)
        case .requestUpdateAudience(let audience):
            return .updateAudience(audience)
        default:
            return .metaSheet(action)
        }
    }
}

//  MARK: Model
struct DetailModel: ModelProtocol {
    var address: MemoAddress?
    var defaultAudience = Audience.local
    var audience: Audience {
        address?.toAudience() ?? defaultAudience
    }
    /// Required headers
    /// Initialize date with Unix Epoch
    var headers = WellKnownHeaders(
        contentType: ContentType.subtext.rawValue,
        created: Date.distantPast,
        modified: Date.distantPast,
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
    var selectedShortlink: Subtext.Shortlink?
    
    /// The text editor
    var editor = SubtextTextModel()
    
    /// Meta bottom sheet is presented?
    var isMetaSheetPresented = false
    /// Meta bottom sheet model
    var metaSheet = DetailMetaSheetModel()
    
    /// Link suggestions for modal and bar in edit mode
    var isLinkSheetPresented = false
    var linkSearchText = ""
    var linkSuggestions: [LinkSuggestion] = []
    
    /// Time interval after which a load is considered stale, and should be
    /// reloaded to make sure it is fresh.
    static let loadStaleInterval: TimeInterval = 0.2
    
    /// Given a particular entry value, does the editor's state
    /// currently match it, such that we could say the editor is
    /// displaying that entry?
    func stateMatches(entry: MemoEntry) -> Bool {
        return (
            self.address == entry.address &&
            editor.text == entry.contents.body.description
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
        case .metaSheet(let action):
            return DetailMetaSheetCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .editor(let action):
            return DetailEditorCursor.update(
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
        case let .appear(info):
            return appear(
                state: state,
                environment: environment,
                info: info
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
        case let .loadDetail(address, fallback, autofocus):
            return loadDetail(
                state: state,
                environment: environment,
                address: address,
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
        case let .setDraftDetail(defaultAudience, fallback):
            return setDraftDetail(
                state: state,
                environment: environment,
                defaultAudience: defaultAudience,
                fallback: fallback
            )
        case .resetDetail:
            return resetDetail(
                state: state,
                environment: environment
            )
        case .doneEditing:
            return doneEditing(
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
        case let .failSave(address, message):
            return failSave(
                state: state,
                environment: environment,
                address: address,
                message: message
            )
        case let .presentMetaSheet(isPresented):
            return presentMetaSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
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
        case let .updateAudience(audience):
            return updateAudience(
                state: state,
                environment: environment,
                audience: audience
            )
        case let .succeedUpdateAudience(receipt):
            return succeedUpdateAudience(
                state: state,
                environment: environment,
                receipt: receipt
            )
        case let .failUpdateAudience(message):
            return log(
                state: state,
                environment: environment,
                message: message
            )
        case let .selectRenameSuggestion(suggestion):
            return selectRenameSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
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
        info: DetailOuterModel
    ) -> Update<DetailModel> {
        // No address? This is a draft.
        guard let address = info.address else {
            return update(
                state: state,
                action: .setDraftDetail(
                    defaultAudience: info.defaultAudience,
                    fallback: info.fallback
                ),
                environment: environment
            )
        }
        // Address? Attempt to load detail.
        return update(
            state: state,
            action: .loadDetail(
                address: address,
                fallback: info.fallback,
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
        model.headers.modified = modified
        return update(
            state: model,
            action: .editor(.setText(text)),
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
                    .editor(.focusChange(false)),
                    .autosave
                ],
                environment: environment
            )
        }
        // Otherwise, just send down focus request
        return update(
            state: state,
            action: .editor(.focusChange(true)),
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
        let link = dom.shortlinkFor(range: nsRange)
        var model = state
        model.selectedShortlink = link
        
        let linkSearchText = link?.toTitle() ?? ""
        
        return DetailModel.update(
            state: model,
            actions: [
                // Immediately send down setSelection
                DetailAction.editor(
                    SubtextTextAction.setSelection(
                        range: nsRange,
                        text: text
                    )
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
        guard let range = Range(nsRange, in: state.editor.text) else {
            logger.log(
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
                    saveState: .unsaved,
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
        address: MemoAddress,
        fallback: String,
        autofocus: Bool
    ) -> Update<DetailModel> {
        let fx: Fx<DetailAction> = environment.data.readDetailAsync(
            address: address,
            fallback: fallback
        ).map({ detail in
            DetailAction.setDetail(
                detail: detail,
                autofocus: autofocus
            )
        }).catch({ error in
            Just(DetailAction.failLoadDetail(error.localizedDescription))
        }).eraseToAnyPublisher()
        
        let model = prepareLoadDetail(state)
        return Update(state: model, fx: fx)
    }
    
    /// Reload detail
    static func refreshDetail(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        guard let address = state.address else {
            logger.log(
                "Refresh detail requested when nothing was being edited. Skipping."
            )
            return Update(state: state)
        }
        
        let model = prepareLoadDetail(state)
        
        let fx: Fx<DetailAction> = environment.data.readDetailAsync(
            address: address,
            fallback: model.editor.text
        ).map({ detail in
            DetailAction.setDetailLastWriteWins(detail)
        }).catch({ error in
            Just(DetailAction.failLoadDetail(error.localizedDescription))
        }).eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func refreshDetailIfStale(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        guard let address = state.address else {
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
            "Detail for \(address) is stale. Refreshing."
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
        logger.log("Detail load failed with message: \(message)")
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
        model.address = detail.entry.address
        model.defaultAudience = detail.entry.address.toAudience()
        model.headers = detail.entry.contents.wellKnownHeaders()
        model.additionalHeaders = detail.entry.contents.additionalHeaders
        model.backlinks = detail.backlinks
        model.saveState = detail.saveState
        
        let subtext = detail.entry.contents.body
        let text = String(describing: subtext)
        
        return DetailModel.update(
            state: model,
            actions: [
                .setMetaSheetAddress(model.address),
                .setEditor(
                    text: text,
                    saveState: detail.saveState,
                    modified: model.headers.modified
                )
            ],
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
    
    static func setDraftDetail(
        state: DetailModel,
        environment: AppEnvironment,
        defaultAudience: Audience,
        fallback: String
    ) -> Update<DetailModel> {
        var model = state

        model.defaultAudience = defaultAudience

        return update(
            state: model,
            actions: [
                .setMetaSheetDefaultAudience(defaultAudience),
                .setEditor(
                    text: fallback,
                    saveState: .unsaved,
                    modified: Date.now
                )
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
        model.address = nil
        model.headers = WellKnownHeaders(
            contentType: ContentType.subtext.rawValue,
            created: Date.distantPast,
            modified: Date.distantPast,
            fileExtension: ContentType.subtext.fileExtension
        )
        model.additionalHeaders = []
        model.editor = SubtextTextModel()
        model.backlinks = []
        model.isLoading = true
        model.saveState = .saved
        return Update(state: model)
    }
    
    static func updateAudience(
        state: DetailModel,
        environment: AppEnvironment,
        audience: Audience
    ) -> Update<DetailModel> {
        guard let from = state.address else {
            logger.log(
                "Update audience requested, but no memo is being edited."
            )
            return Update(state: state)
        }

        let to = from.withAudience(audience)

        let fx: Fx<DetailAction> = environment.data.moveEntryAsync(
            from: from,
            to: to
        ).map({ receipt in
            DetailAction.succeedUpdateAudience(receipt)
        }).catch({ error in
            Just(DetailAction.failUpdateAudience(error.localizedDescription))
        }).eraseToAnyPublisher()

        var model = state
        model.address = to
        
        return update(
            state: model,
            action: .metaSheet(.requestUpdateAudience(audience)),
            environment: environment
        ).mergeFx(fx)
    }
    
    static func succeedUpdateAudience(
        state: DetailModel,
        environment: AppEnvironment,
        receipt: MoveReceipt
    ) -> Update<DetailModel> {
        guard state.address != nil else {
            return Update(state: state)
        }
        var model = state
        model.address = receipt.to
        return update(
            state: model,
            // Forrward success down to meta sheet
            action: .metaSheet(.succeedUpdateAudience(receipt)),
            environment: environment
        )
    }
    
    static func doneEditing(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        update(
            state: state,
            actions: [
                .autosave,
                .requestEditorFocus(false)
            ],
            environment: environment
        )
    }
    
    static func autosave(
        state: DetailModel,
        environment: AppEnvironment
    ) -> Update<DetailModel> {
        /// If no address, derive one and update
        guard state.address != nil else {
            let address = environment.data.findUniqueAddressFor(
                state.editor.text,
                audience: state.defaultAudience
            )
            var model = state
            model.address = address

            let entry = model.snapshotEntry()

            return update(
                state: model,
                actions: [
                    .save(entry),
                    .setMetaSheetAddress(address)
                ],
                environment: environment
            )
        }
        
        let entry = state.snapshotEntry()
        return update(
            state: state,
            action: .save(entry),
            environment: environment
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
                        address: entry.address,
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
        logger.debug(
            "Saved entry: \(entry.address)"
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
        address: MemoAddress,
        message: String
    ) -> Update<DetailModel> {
        //  TODO: show user a "try again" banner
        logger.warning(
            "Save failed for entry (\(address)) with error: \(message)"
        )
        // Mark modified, since we failed to save
        var model = state
        model.saveState = .unsaved
        return Update(state: model)
    }
    
    static func presentMetaSheet(
        state: DetailModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<DetailModel> {
        var model = state
        model.isMetaSheetPresented = isPresented
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
        var omitting: Set<MemoAddress> = Set()
        if let address = state.address {
            omitting.insert(address)
        }
        
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
            state.selectedShortlink,
            through: { markup in
                switch markup {
                case .slashlink(let slashlink):
                    let replacement = link.address.slug.markup
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
    
    static func selectRenameSuggestion(
        state: DetailModel,
        environment: AppEnvironment,
        suggestion: RenameSuggestion
    ) -> Update<DetailModel> {
        update(
            state: state,
            actions: [
                // Forward intercepted action down to child
                .metaSheet(.selectRenameSuggestion(suggestion)),
                // Additionally, act on rename suggestion
                DetailAction.from(suggestion)
            ],
            environment: environment
        )

    }

    /// Move entry
    static func moveEntry(
        state: DetailModel,
        environment: AppEnvironment,
        from: MemoAddress,
        to: MemoAddress
    ) -> Update<DetailModel> {
        let fx: Fx<DetailAction> = environment.data.moveEntryAsync(
            from: from,
            to: to
        )
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
        from: MemoAddress,
        to: MemoAddress
    ) -> Update<DetailModel> {
        guard state.address == from else {
            logger.warning(
                """
                Detail got a succeedMoveEntry action that doesn't match address. Doing nothing.
                Detail address: \(state.address?.description ?? "None")
                From address: \(from.description)
                To address: \(to.description)
                """
            )
            return Update(state: state)
        }
        
        var model = state
        model.address = to
        
        return update(
            state: model,
            actions: [
                .metaSheet(.setAddress(to)),
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
        logger.warning(
            "Failed to move entry with error: \(error)"
        )
        return Update(state: state)
    }
    
    /// Merge entry
    static func mergeEntry(
        state: DetailModel,
        environment: AppEnvironment,
        parent: MemoAddress,
        child: MemoAddress
    ) -> Update<DetailModel> {
        let fx: Fx<DetailAction> = environment.data.mergeEntryAsync(
            parent: parent,
            child: child
        ).map({ _ in
            DetailAction.succeedMergeEntry(parent: parent, child: child)
        }).catch({ error in
            Just(
                DetailAction.failMergeEntry(error.localizedDescription)
            )
        }).eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: DetailModel,
        environment: AppEnvironment,
        parent: MemoAddress,
        child: MemoAddress
    ) -> Update<DetailModel> {
        var model = state
        model.address = parent
        return update(
            state: model,
            actions: [
                .metaSheet(.setAddress(parent)),
                .refreshLists,
                .refreshDetail
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
        logger.warning(
            "Failed to merge entry with error: \(error)"
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
    ) -> Update<DetailModel>
    where T: TaggedMarkup
    {
        guard let range = Range(nsRange, in: state.editor.text) else {
            logger.log(
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
                    saveState: .unsaved,
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
    
    func excerpt(fallback: String = "") -> String {
        Subtext.excerpt(markup: self.editor.text, fallback: fallback)
    }
}

//  MARK: Outer Model
/// A description of a detail suitible for pushing onto a navigation stack
struct DetailOuterModel: Hashable, ModelProtocol {
    var address: MemoAddress?
    var fallback: String = ""
    /// Default audience to use when deriving a memo address
    var defaultAudience = Audience.local
    
    static func update(
        state: DetailOuterModel,
        action: DetailOuterAction,
        environment: AppEnvironment
    ) -> ObservableStore.Update<DetailOuterModel> {
        Update(state: state)
    }
}

extension FileFingerprint {
    /// Initialize FileFingerprint from DetailModel.
    /// We use this to do last-write-wins.
    init?(_ detail: DetailModel) {
        guard let slug = detail.address?.slug else {
            return nil
        }
        self.init(
            slug: slug,
            modified: detail.headers.modified,
            text: detail.editor.text
        )
    }
}

extension MemoEntry {
    init?(_ detail: DetailModel) {
        guard let address = detail.address else {
            return nil
        }
        self.address = address
        self.contents = Memo(
            contentType: detail.headers.contentType,
            created: detail.headers.created,
            modified: detail.headers.modified,
            fileExtension: detail.headers.fileExtension,
            additionalHeaders: detail.additionalHeaders,
            body: detail.editor.text
        )
    }
}

struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(
            state: DetailOuterModel(
                address: Slug(formatting: "Nothing is lost in the universe")!
                    .toPublicMemoAddress(),
                fallback: "Nothing is lost in the universe"
            ),
            send: { action in }
        )
    }
}
