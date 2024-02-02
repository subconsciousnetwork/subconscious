//
//  MemoEditorDetailView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI
import os
import ObservableStore
import Combine

// MARK: View
struct MemoEditorDetailView: View {
    private static let blockEditorStoreLogger = Logger(
        subsystem: Config.default.rdns,
        category: "BlockEditorStore"
    )

    private static let memoEditorDetailStoreLogger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoEditorDetailStore"
    )

    typealias Action = MemoEditorDetailAction
    @ObservedObject var app: Store<AppModel>
    
    /// Detail keeps a separate internal store for editor state that does not
    /// need to be surfaced in higher level views.
    ///
    /// This gives us a pretty big efficiency win, since keystrokes will only
    /// rerender this view, and not whole app view tree.
    @StateObject private var store = Store(
        state: MemoEditorDetailModel(),
        action: .start,
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: memoEditorDetailStoreLogger
    )
    
    @StateObject private var blockEditorStore = Store(
        state: BlockEditor.Model.draft(),
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: blockEditorStoreLogger
    )
    
    /// Is this view presented? Used to detect when back button is pressed.
    /// We trigger an autosave when isPresented is false below.
    @Environment(\.isPresented) var isPresented
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    @Environment(\.colorScheme) var colorScheme
    /// Initialization state passed down from parent
    var description: MemoEditorDetailDescription
    /// An address to forward notifications (informational actions)
    var notify: (MemoEditorDetailNotification) -> Void
    var navigationTitle: String {
        switch store.state.audience {
        case .local:
            return store.state.address?.slug.markup ?? store.state.title
        case .public:
            return store.state.address?.markup ?? store.state.title
        }
    }
    
    private func onLink(
        url: URL
    ) -> Bool {
        guard let link = url.toSubSlashlinkLink()?.toEntryLink() else {
            return true
        }
        notify(.requestFindLinkDetail(link))
        return false
    }
    
    var body: some View {
        VStack {
            if app.state.isBlockEditorEnabled {
                blockEditor()
            } else {
                plainEditor()
            }
        }
        .background(
            colorScheme == .dark ? DeckTheme.darkBg : DeckTheme.lightBg
        )
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            colorScheme == .dark
            ? DeckTheme.darkBgStart
            : DeckTheme.lightBgStart,
            for: .navigationBar
        )
        .toolbarBackground(
            colorScheme == .dark ? DeckTheme.darkBgEnd : DeckTheme.lightBgEnd,
            for: .tabBar
        )
        .toolbar(content: {
            DetailToolbarContent(
                address: store.state.address,
                defaultAudience: store.state.defaultAudience,
                onTapOmnibox: {
                    store.send(.presentMetaSheet(true))
                },
                status: store.state.loadingState
            )
        })
        .onAppear {
            // When an editor is presented, refresh if stale.
            // This covers the case where the editor might have been in the
            // background for a while, and the content changed in another tab.
            store.send(MemoEditorDetailAction.appear(description))
            blockEditorStore.send(.appear(description))
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(.scenePhaseChange(phase))
            blockEditorStore.send(.scenePhaseChange(phase))
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
                blockEditorStore.send(.autosave)
            }
        }
        /// Catch link taps and handle them here
        .environment(\.openURL, OpenURLAction { url in
            if self.onLink(url: url) {
                return .handled
            }
            
            return .systemAction
        })
        // Filtermap actions to outer actions, and forward them to parent
        .onReceive(
            store.actions.compactMap(MemoEditorDetailNotification.from)
        ) { action in
            notify(action)
        }
        .onReceive(
            app.actions.compactMap(MemoEditorDetailAction.fromAppAction),
            perform: store.send
        )
        .sheet(
            isPresented: Binding(
                get: { store.state.isMetaSheetPresented },
                send: store.send,
                tag: MemoEditorDetailAction.presentMetaSheet
            )
        ) {
            MemoEditorDetailMetaSheetView(
                store: store.viewStore(
                    get: \.metaSheet,
                    tag: MemoEditorDetailMetaSheetCursor.tag
                )
            )
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isLinkSheetPresented },
                send: store.send,
                tag: MemoEditorDetailAction.setLinkSheetPresented
            )
        ) {
            LinkSearchView(
                placeholder: "Search or create...",
                suggestions: store.state.linkSuggestions,
                text: Binding(
                    get: { store.state.linkSearchText },
                    send: store.send,
                    tag: MemoEditorDetailAction.setLinkSearch
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
    
    private func blockEditor() -> some View {
        BlockEditor.Representable(
            store: blockEditorStore
        )
        .frame(
            minHeight: UIFont.appTextMono.lineHeight * 8
        )
        .onReceive(
            blockEditorStore.actions.compactMap(
                MemoEditorDetailNotification.from
            ),
            perform: notify
        )
    }
    
    var highlight: Color? {
        store.state.themeColor?.toHighlightColor()
    }

    /// Constructs a plain text editor for the view
    private func plainEditor() -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        SubtextTextViewRepresentable( state: store.state.editor, send: Address.forward(
                                send: store.send,
                                tag: MemoEditorDetailSubtextTextCursor.tag
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
                        .tint(highlight)
                        .background(
                            store.state.themeColor?.toColor()
                                ?? store.state.address?.themeColor.toColor()
                        )
                        .cornerRadius(DeckTheme.cornerRadius, corners: .allCorners)
                        .shadow(
                            color: DeckTheme.cardShadow.opacity(0.08),
                            radius: 1.5,
                            x: 0,
                            y: 1.5
                        )
                        .padding(.bottom, AppTheme.unit4)
                        .padding(.top, AppTheme.unit2)
                        
                        BacklinksView(
                            backlinks: store.state.backlinks,
                            onLink: { link in
                                notify(.requestFindLinkDetail(link))
                            }
                        )
                    }
                }
                if store.state.editor.focus {
                    DetailKeyboardToolbarView(
                        isSheetPresented: Binding(
                            get: { store.state.isLinkSheetPresented },
                            send: store.send,
                            tag: MemoEditorDetailAction.setLinkSheetPresented
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
    }
}

// MARK: Action

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum MemoEditorDetailNotification: Hashable {
    /// Request specific detail
    case requestDetail(MemoDetailDescription)
    /// Request detail from any audience scope
    case requestFindLinkDetail(EntryLink)
    
    case requestSaveEntry(MemoEntry)
    case requestDelete(Slashlink?)
    case requestMoveEntry(from: Slashlink, to: Slashlink)
    case requestMergeEntry(parent: Slashlink, child: Slashlink)
    case requestUpdateAudience(address: Slashlink, audience: Audience)
    case requestAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    case requestQuoteInNewDetail(_ address: Slashlink)
    case selectAppendLinkSearchSuggestion(AppendLinkSuggestion)
}

extension MemoEditorDetailNotification {
    static func from(_ action: MemoEditorDetailAction) -> Self? {
        switch action {
        case let .forwardRequestSaveEntry(entry):
            return .requestSaveEntry(entry)
        case .forwardRequestDelete(let address):
            return .requestDelete(address)
        case let .forwardRequestMoveEntry(from, to):
            return .requestMoveEntry(from: from, to: to)
        case let .forwardRequestMergeEntry(parent, child):
            return .requestMergeEntry(parent: parent, child: child)
        case let .forwardRequestUpdateAudience(address, audience):
            return .requestUpdateAudience(address: address, audience: audience)
        case let .forwardRequestAssignNoteColor(address, color):
            return .requestAssignNoteColor(address, color)
        case let .requestQuoteInNewNote(address):
            return .requestQuoteInNewDetail(address)
        case let .selectAppendLinkSearchSuggestion(suggestion):
            return .selectAppendLinkSearchSuggestion(suggestion)
        default:
            return nil
        }
    }
}

extension MemoEditorDetailNotification {
    static func from(_ action: BlockEditor.Action) -> Self? {
        switch action {
        case let .forwardRequestSave(snapshot):
            return .requestSaveEntry(snapshot)
        case let .requestFindLinkDetail(link):
            return .requestFindLinkDetail(link)
        default:
            return nil
        }
    }
}

/// Actions handled by detail's private store.
enum MemoEditorDetailAction: Hashable {
    /// Tagging action for detail meta bottom sheet
    case metaSheet(MemoEditorDetailMetaSheetAction)

    /// Sent once and only once on Store initialization
    case start

    /// When scene phase changes.
    /// E.g. when app is foregrounded, backgrounded, etc.
    case scenePhaseChange(ScenePhase)

    /// Wrapper for editor actions
    case editor(SubtextTextAction)

    case appear(MemoEditorDetailDescription)

    // Detail
    /// Load detail, using a last-write-wins strategy for replacement
    /// if detail is already loaded.
    case loadDetail(
        address: Slashlink,
        fallback: String,
        autofocus: Bool
    )
    /// Reload detail from source of truth
    case refreshDetail
    case refreshDetailIfStale
    
    case refreshBacklinks
    case succeedRefreshBacklinks(_ backlinks: [EntryStub])
    case failRefreshBacklinks(_ error: String)
    
    /// Unable to load detail
    case failLoadDetail(String)
    /// Set entry detail.
    /// This actions will blow away any existing entry detail.
    /// In most cases you want to use `setDetailLastWriteWins` instead.
    case forceSetDetail(MemoEditorDetailResponse)
    /// Set EntryDetail on DetailModel, but only if last modification happened
    /// more recently than DetailModel.
    case setDetailLastWriteWins(MemoEditorDetailResponse)
    /// Set detail
    case setDetail(
        detail: MemoEditorDetailResponse,
        autofocus: Bool
    )
    case setDraftDetail(
        defaultAudience: Audience,
        fallback: String
    )
    /// Set detail to initial conditions
    case resetDetail

    /// Finish with editing focus
    case doneEditing

    //  Saving entry
    /// Trigger autosave of current state
    case autosave

    //  Give memo an address if it doesn't have one
    case requestAssignAddress
    case assignAddress(Slashlink?)


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
    
    /// Note lifecycle events.
    /// `request`s are handled here and dispatch `forward`s
    /// `forward`s are passed up to the app root
    /// `succeed`s are passed down from the app root
    case requestSaveEntry(MemoEntry) // prepare our state for saving
    case forwardRequestSaveEntry(MemoEntry) // request save at app level
    case succeedSave(address: Slashlink, modified: Date) // respond to save success
    case requestDelete(_ address: Slashlink?)
    case forwardRequestDelete(_ address: Slashlink?)
    case requestMoveEntry(from: Slashlink, to: Slashlink)
    case forwardRequestMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case requestMergeEntry(parent: Slashlink, child: Slashlink)
    case forwardRequestMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case requestUpdateAudience(_ audience: Audience)
    case forwardRequestUpdateAudience(address: Slashlink, _ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    case requestAssignNoteColor(_ color: ThemeColor)
    case forwardRequestAssignNoteColor(address: Slashlink, _ color: ThemeColor)
    case succeedAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    

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
    
    case requestQuoteInNewNote(_ address: Slashlink)
    case selectAppendLinkSearchSuggestion(AppendLinkSuggestion)

    /// Local action for requesting editor focus.
    static func requestEditorFocus(_ focus: Bool) -> Self {
        .editor(.requestFocus(focus))
    }

    static var setEditorSelectionAtEnd: Self {
        .editor(.setSelectionAtEnd)
    }
    
    static var setEditorSelectionAtStart: Self {
        .editor(.setSelectionAtStart)
    }

    /// Select a link completion
    static func selectLinkCompletion(_ link: EntryLink) -> Self {
        .selectLinkSuggestion(.entry(link))
    }

    static var refreshRenameSuggestions: Self {
        .metaSheet(.refreshRenameSuggestions)
    }

    static func setMetaSheetAddress(_ address: Slashlink?) -> Self {
        .metaSheet(.setAddress(address))
    }
    
    static func setMetaSheetColor(_ color: ThemeColor?) -> Self {
        .metaSheet(.setNoteColor(color))
    }

    static func setMetaSheetDefaultAudience(_ audience: Audience) -> Self {
        .metaSheet(.setDefaultAudience(audience))
    }
}

extension MemoEditorDetailAction {
    static func from(_ suggestion: RenameSuggestion) -> Self {
        switch suggestion {
        case let .move(from, to):
            return .requestMoveEntry(from: from, to: to)
        case let .merge(parent, child):
            return .requestMergeEntry(parent: parent, child: child)
        }
    }
}

/// React to actions from the root app store
extension MemoEditorDetailAction {
    static func fromAppAction(
        action: AppAction
    ) -> MemoEditorDetailAction? {
        switch (action) {
        case let .succeedSaveEntry(address, modified):
            return .succeedSave(address: address, modified: modified)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent: parent, child: child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        case let .succeedAssignNoteColor(address, color):
            return .succeedAssignNoteColor(address, color)
            
        case .succeedIndexOurSphere(_),
             .completeIndexPeers:
            return .refreshBacklinks
        case _:
            return nil
        }
    }
}

// MARK: Cursors
/// Editor cursor
struct MemoEditorDetailSubtextTextCursor: CursorProtocol {
    static func get(state: MemoEditorDetailModel) -> SubtextTextModel {
        state.editor
    }

    static func set(
        state: MemoEditorDetailModel,
        inner: SubtextTextModel
    ) -> MemoEditorDetailModel {
        var model = state
        model.editor = inner
        return model
    }

    static func tag(_ action: SubtextTextAction) -> MemoEditorDetailAction {
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

struct MemoEditorDetailMetaSheetCursor: CursorProtocol {
    typealias Model = MemoEditorDetailModel
    typealias ViewModel = MemoEditorDetailMetaSheetModel

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
        case let .requestUpdateAudience(audience):
            return .requestUpdateAudience(audience)
        case let .requestAssignNoteColor(color):
            return .requestAssignNoteColor(color)
        case .requestDelete(let address):
            return .requestDelete(address)
        case let .requestQuoteInNewNote(address):
            return .requestQuoteInNewNote(address)
        case let .selectAppendLinkSearchSuggestion(suggestion):
            return .selectAppendLinkSearchSuggestion(suggestion)
        default:
            return .metaSheet(action)
        }
    }
}

// MARK: Model
struct MemoEditorDetailModel: ModelProtocol {
    var address: Slashlink?
    var defaultAudience = Audience.local
    var audience: Audience {
        address?.toAudience() ?? defaultAudience
    }

    // Derive title from editor state
    var title: String {
        editor.text.title()
    }

    /// Required headers
    /// Initialize date with Unix Epoch
    var headers = WellKnownHeaders(
        contentType: ContentType.subtext.rawValue,
        created: Date.distantPast,
        modified: Date.distantPast,
        fileExtension: ContentType.subtext.fileExtension
    )
    var themeColor: ThemeColor? = nil
    
    /// Additional headers that are not well-known headers.
    var additionalHeaders: Headers = []
    var backlinks: [EntryStub] = []
    
    /// Is editor saved?
    var saveState = SaveState.saved
    
    /// Is editor in loading state?
    var loadingState = LoadingState.loading
    /// When was the last time the editor issued a fetch from source of truth?
    var lastLoadStarted = Date.distantPast
    
    /// The entry link within the text
    var selectedShortlink: Subtext.Shortlink?
    
    /// The text editor
    var editor = SubtextTextModel()
    
    /// Meta bottom sheet is presented?
    var isMetaSheetPresented = false
    /// Meta bottom sheet model
    var metaSheet = MemoEditorDetailMetaSheetModel()
    
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
        category: "MemoEditorDetail"
    )
    
    // MARK: Update
    static func update(
        state: MemoEditorDetailModel,
        action: MemoEditorDetailAction,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        switch action {
        case .metaSheet(let action):
            return MemoEditorDetailMetaSheetCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .editor(let action):
            return MemoEditorDetailSubtextTextCursor.update(
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
            
        case .refreshBacklinks:
            return refreshBacklinks(
                state: state,
                environment: environment
            )
        case .succeedRefreshBacklinks(let backlinks):
            var model = state
            model.backlinks = backlinks
            return Update(state: model)
        case .failRefreshBacklinks(let error):
            logger.error("Failed to refresh backlinks: \(error)")
            return Update(state: state)
            
        case .requestDelete(let address):
            return requestDelete(
                state: state,
                environment: environment,
                address: address
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
        case .requestAssignAddress:
            return requestAssignAddress(
                state: state,
                environment: environment
            )
        case .assignAddress(let address):
            return assignAddress(
                state: state,
                environment: environment,
                address: address
            )
        case .requestSaveEntry(let entry):
            return requestSave(
                state: state,
                environment: environment,
                entry: entry
            )
        case let .succeedSave(address, _):
            return succeedSave(
                state: state,
                environment: environment,
                address: address
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
        case let .requestUpdateAudience(audience):
            return requestUpdateAudience(
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
        case let .requestAssignNoteColor(color):
            return requestAssignNoteColor(
                state: state,
                environment: environment,
                color: color
            )
        case let .succeedAssignNoteColor(address, color):
            return succeedAssignNoteColor(
                state: state,
                environment: environment,
                address: address,
                color: color
            )
        case let .selectRenameSuggestion(suggestion):
            return selectRenameSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case .requestMoveEntry(let from, let to):
            return requestMoveEntry(
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
        case .requestMergeEntry(let parent, let child):
            return requestMergeEntry(
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
        case .requestQuoteInNewNote:
            return update(
                state: state,
                action: .presentMetaSheet(false),
                environment: environment
            )
        case let .selectAppendLinkSearchSuggestion(suggestion):
            return update(
                state: state,
                actions: [
                    .metaSheet(.selectAppendLinkSearchSuggestion(suggestion)),
                    .presentMetaSheet(false)
                ],
                environment: environment
            )
        case .forwardRequestSaveEntry, .forwardRequestDelete, .forwardRequestMoveEntry,
                .forwardRequestMergeEntry, .forwardRequestUpdateAudience,
                .forwardRequestAssignNoteColor:
            return Update(state: state)
        }
    }
    
    /// Log debug
    static func log(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<MemoEditorDetailModel> {
        logger.log("\(message)")
        return Update(state: state)
    }
    
    /// Log debug
    static func logDebug(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<MemoEditorDetailModel> {
        logger.debug("\(message)")
        return Update(state: state)
    }
    
    /// Log debug
    static func logWarning(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<MemoEditorDetailModel> {
        logger.warning("\(message)")
        return Update(state: state)
    }
    
    static func start(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        let pollFx = AppEnvironment.poll(every: Config.default.pollingInterval)
            .map({ _ in MemoEditorDetailAction.autosave })
            .eraseToAnyPublisher()
        return Update(state: state, fx: pollFx)
    }
    
    /// Handle scene phase change
    /// We trigger an autosave when scene becomes inactive.
    static func scenePhaseChange(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        phase: ScenePhase
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        info: MemoEditorDetailDescription
    ) -> Update<MemoEditorDetailModel> {
        // No address? This is a draft.
        guard let address = info.address ?? state.address else {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        text: String,
        saveState: SaveState,
        modified: Date
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        model.saveState = saveState
        model.loadingState = .loaded
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        isFocused: Bool
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        text: String
    ) -> Update<MemoEditorDetailModel> {
        // Set entry link based on selection
        let dom = Subtext.parse(markup: text)
        let link = dom.shortlinkFor(range: nsRange)
        var model = state
        model.selectedShortlink = link
        
        let linkSearchText = link?.toTitle() ?? ""
        
        return MemoEditorDetailModel.update(
            state: model,
            actions: [
                // Immediately send down setSelection
                MemoEditorDetailAction.editor(
                    SubtextTextAction.setSelection(
                        range: nsRange,
                        text: text
                    )
                ),
                MemoEditorDetailAction.setLinkSearch(linkSearchText)
            ],
            environment: environment
        )
    }
    
    /// Insert text in editor at range
    static func insertEditorText(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        text: String,
        range nsRange: NSRange
    ) -> Update<MemoEditorDetailModel> {
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
        return MemoEditorDetailModel.update(
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
    static func prepareLoadDetail(_ state: MemoEditorDetailModel) -> MemoEditorDetailModel {
        var model = state
        // Mark loading state
        model.loadingState = .loading
        // Mark time of load start
        model.lastLoadStarted = Date.now
        return model
    }
    
    /// Load Detail from database and present detail
    static func loadDetail(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        address: Slashlink,
        fallback: String,
        autofocus: Bool
    ) -> Update<MemoEditorDetailModel> {
        let fx: Fx<MemoEditorDetailAction> = environment.data.readMemoEditorDetailPublisher(
            address: address,
            fallback: fallback
        ).map({ detail in
            MemoEditorDetailAction.setDetail(
                detail: detail,
                autofocus: autofocus
            )
        }).catch({ error in
            Just(MemoEditorDetailAction.failLoadDetail(error.localizedDescription))
        }).eraseToAnyPublisher()
        
        var model = prepareLoadDetail(state)
        model.address = address
        
        return update(
            state: model,
            action: .refreshBacklinks,
            environment: environment
        ).mergeFx(fx)
    }
    
    /// Reload detail
    static func refreshDetail(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        guard let address = state.address else {
            logger.log(
                "Refresh detail requested when nothing was being edited. Skipping."
            )
            return Update(state: state)
        }
        
        let model = prepareLoadDetail(state)
        
        let fx: Fx<MemoEditorDetailAction> = environment.data.readMemoEditorDetailPublisher(
            address: address,
            fallback: model.editor.text
        ).map({ detail in
            MemoEditorDetailAction.setDetailLastWriteWins(detail)
        }).catch({ error in
            Just(MemoEditorDetailAction.failLoadDetail(error.localizedDescription))
        }).eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func refreshDetailIfStale(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<MemoEditorDetailModel> {
        logger.log("Detail load failed with message: \(message)")
        return Update(state: state)
    }
    
    /// Set MemoEditorResponse onto DetailModel
    static func forceSetDetail(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        detail: MemoEditorDetailResponse
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        model.loadingState = .loaded
        model.address = detail.entry.address
        model.defaultAudience = detail.entry.address.toAudience()
        model.headers = detail.entry.contents.wellKnownHeaders()
        model.themeColor = model.headers.themeColor
        model.additionalHeaders = detail.entry.contents.additionalHeaders
        model.saveState = detail.saveState
        
        let subtext = detail.entry.contents.body
        let text = String(describing: subtext)
        
        return MemoEditorDetailModel.update(
            state: model,
            actions: [
                .setMetaSheetAddress(model.address),
                .setMetaSheetColor(model.themeColor),
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        detail: MemoEditorDetailResponse
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        // Mark loading finished
        model.loadingState = .loaded
        
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
                    snapshot.map(MemoEditorDetailAction.requestSaveEntry),
                    .forceSetDetail(detail)
                ].compactMap({ v in v }),
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        detail: MemoEditorDetailResponse,
        autofocus: Bool
    ) -> Update<MemoEditorDetailModel> {
        var actions: [MemoEditorDetailAction] = [
            .setDetailLastWriteWins(detail)
        ]
        
        // If autofocus is true, request focus, and also set selection to end
        // of editor text.
        if autofocus {
            actions.append(.requestEditorFocus(autofocus))
            actions.append(.setEditorSelectionAtEnd)
        }
        
        return update(
            state: state,
            actions: actions,
            environment: environment
        )
    }
    
    static func setDraftDetail(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        defaultAudience: Audience,
        fallback: String
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        
        model.defaultAudience = defaultAudience
        
        // if fallback starts with newlines, cursor at start
        // otherwise, cursor at end
        var selection = MemoEditorDetailAction.setEditorSelectionAtEnd
        if let first = fallback.first,
           first.isNewline {
            selection = .setEditorSelectionAtStart
        }
        
        return update(
            state: model,
            actions: [
                .setMetaSheetDefaultAudience(defaultAudience),
                .setEditor(
                    text: fallback,
                    saveState: .unsaved,
                    modified: Date.now
                ),
                selection,
                .requestEditorFocus(true)
            ],
            environment: environment
        )
    }

    /// Reset model to "none" condition
    static func resetDetail(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
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
        model.loadingState = .loading
        model.saveState = .saved
        return Update(state: model)
    }
    
    static func refreshBacklinks(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        guard let address = state.address else {
            return Update(state: state)
        }
        
        let fx: Fx<MemoEditorDetailAction> = Future.detached {
            try await environment.data.readMemoBacklinks(address: address)
        }
        .map { backlinks in
            .succeedRefreshBacklinks(backlinks)
        }
        .recover { error in
            .failRefreshBacklinks(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedUpdateAudience(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        receipt: MoveReceipt
    ) -> Update<MemoEditorDetailModel> {
        guard state.address != nil else {
            return Update(state: state)
        }
        var model = state
        model.address = receipt.to
        return update(
            state: model,
            // Forward success down to meta sheet
            action: .metaSheet(.succeedUpdateAudience(receipt)),
            environment: environment
        )
    }

    static func requestDelete(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        address: Slashlink?
    ) -> Update<MemoEditorDetailModel> {
        let delay = Duration.sheet
        
        let fx: Fx<MemoEditorDetailAction> = Just(
            MemoEditorDetailAction.forwardRequestDelete(address)
        ).delay(
            for: .seconds(delay),
            scheduler: DispatchQueue.main
        ).eraseToAnyPublisher()

        return update(
            state: state,
            actions: [
                .metaSheet(.requestDelete(address)),
                .presentMetaSheet(false)
            ],
            environment: environment
        ).mergeFx(fx)
    }

    static func doneEditing(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        /// If no address, derive one and update
        guard state.address != nil else {
            return update(
                state: state,
                action: .requestAssignAddress,
                environment: environment
            )
        }
        
        guard let entry = state.snapshotEntry() else {
            return Update(state: state)
        }
        
        return update(
            state: state,
            action: .requestSaveEntry(entry),
            environment: environment
        )
    }
    
    static func requestAssignAddress(
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        let fx: Fx<MemoEditorDetailAction> = environment.data
            .findUniqueAddressForPublisher(
                state.editor.text,
                audience: state.defaultAudience
            ).map({ address in
                MemoEditorDetailAction.assignAddress(address)
            }).eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }
    
    static func assignAddress(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        address: Slashlink?
    ) -> Update<MemoEditorDetailModel> {
        guard let address = address else {
            logger.log("Did not get unique address for note. Doing nothing.")
            return Update(state: state)
        }
        
        var model = state
        model.address = address
        
        let entry = model.snapshotEntry()
        
        return update(
            state: model,
            actions: [
                entry.map(MemoEditorDetailAction.requestSaveEntry),
                .setMetaSheetAddress(address)
            ].compactMap({ v in v }),
            environment: environment
        )
        .animation(.default)
    }
    
    /// Save snapshot of entry
    static func requestSave(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        entry: MemoEntry
    ) -> Update<MemoEditorDetailModel> {
        // If editor dom is already saved, noop
        guard state.saveState != .saved else {
            return Update(state: state)
        }
        
        var model = state
        
        // Mark saving in-progress
        model.saveState = .saving
        
        let fx: Fx<MemoEditorDetailAction> = Just(
            MemoEditorDetailAction.forwardRequestSaveEntry(entry)
        ).eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    /// Log save success and perform refresh of various lists.
    static func succeedSave(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        address: Slashlink
    ) -> Update<MemoEditorDetailModel> {
        logger.debug(
            "Saved entry: \(address)"
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
                model.address == address
        {
            model.saveState = .saved
        }
        
        return Update(state: model)
    }
    
    static func presentMetaSheet(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        model.isMetaSheetPresented = isPresented
        return Update(state: model)
    }
    
    static func setLinkSheetPresented(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        model.isLinkSheetPresented = isPresented
        return Update(state: model)
    }
    
    static func setLinkSearch(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        model.linkSearchText = text
        
        // Omit current slug from results
        var omitting: Set<Slashlink> = Set()
        if let address = state.address {
            omitting.insert(address)
        }
        
        // Search link suggestions
        let fx: Fx<MemoEditorDetailAction> = environment.data.searchLinkSuggestionsPublisher(
            query: text,
            omitting: omitting,
            fallback: []
        ).map({ suggestions in
            MemoEditorDetailAction.setLinkSuggestions(suggestions)
        }).catch({ error in
            Just(
                MemoEditorDetailAction.linkSuggestionsFailure(
                    error.localizedDescription
                )
            )
        }).eraseToAnyPublisher()
                    
        return Update(state: model, fx: fx)
    }
    
    static func selectLinkSuggestion(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        suggestion: LinkSuggestion
    ) -> Update<MemoEditorDetailModel> {
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
                    let replacement = link.address.markup
                    let range = NSRange(
                        slashlink.span.range,
                        in: state.editor.text
                    )
                    return (range, replacement)
                case .wikilink(let wikilink):
                    let replacement = Func.run {
                        switch (link.address.peer) {
                            case .none:
                                return Markup.Wikilink(
                                    text: link.linkableTitle
                                ).markup
                            case _:
                                return link.address.markup
                        }
                    }
                    let range = NSRange(
                        wikilink.span.range,
                        in: state.editor.text
                    )
                    return (range, replacement)
                case .none:
                    let replacement = link.address.markup
                    return (state.editor.selection, replacement)
                }
            }
        )
        
        var model = state
        model.linkSearchText = ""
        
        return MemoEditorDetailModel.update(
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        suggestion: RenameSuggestion
    ) -> Update<MemoEditorDetailModel> {
        let fx: Fx<MemoEditorDetailAction> = Future.detached {
            MemoEditorDetailAction.from(suggestion)
        }
        .eraseToAnyPublisher()
        
        return update(
            state: state,
            actions: [
                // Forward intercepted action down to child
                .metaSheet(.selectRenameSuggestion(suggestion)),
            ],
            environment: environment
        ).mergeFx(fx)
    }

    /// Move entry
    static func requestMoveEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        from: Slashlink,
        to: Slashlink
    ) -> Update<MemoEditorDetailModel> {
        let moveFx: Fx<MemoEditorDetailAction> = Just(
            MemoEditorDetailAction.forwardRequestMoveEntry(from: from, to: to)
        ).eraseToAnyPublisher()
        
        let saveFx: Fx<MemoEditorDetailAction> = Just(
            .autosave
        ).eraseToAnyPublisher()
        
        // Save before moving
        let fx = saveFx.merge(with: moveFx).eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
            .animation(.easeOutCubic(duration: Duration.keyboard))
    }
    
    /// Move success lifecycle handler.
    /// Updates UI in response.
    static func succeedMoveEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        from: Slashlink,
        to: Slashlink
    ) -> Update<MemoEditorDetailModel> {
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
    
    /// Merge entry
    static func requestMergeEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        parent: Slashlink,
        child: Slashlink
    ) -> Update<MemoEditorDetailModel> {
        let mergeFx: Fx<MemoEditorDetailAction> = Just(
            .forwardRequestMergeEntry(parent: parent, child: child)
        ).eraseToAnyPublisher()
        
        let saveFx: Fx<MemoEditorDetailAction> = Just(
            .autosave
        ).eraseToAnyPublisher()
        
        // Save before merging
        let fx = saveFx.merge(with: mergeFx).eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        parent: Slashlink,
        child: Slashlink
    ) -> Update<MemoEditorDetailModel> {
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
    
    static func requestUpdateAudience(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        audience: Audience
    ) -> Update<MemoEditorDetailModel> {
        guard let address = state.address else {
            return Update(state: state)
        }
        
        let saveFx: Fx<MemoEditorDetailAction> = Just(
            .autosave
        ).eraseToAnyPublisher()
        
        let audienceFx: Fx<MemoEditorDetailAction> = Just(
            .forwardRequestUpdateAudience(
                address: address,
                audience
            )
        ).eraseToAnyPublisher()
        
        // Save before updating audience
        let fx = saveFx.merge(with: audienceFx).eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func requestAssignNoteColor(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        color: ThemeColor
    ) -> Update<MemoEditorDetailModel> {
        guard let address = state.address else {
            return Update(state: state)
        }
        
        let saveFx: Fx<MemoEditorDetailAction> = Just(
            .autosave
        ).eraseToAnyPublisher()
        
        let audienceFx: Fx<MemoEditorDetailAction> = Just(
            .forwardRequestAssignNoteColor(
                address: address,
                color
            )
        ).eraseToAnyPublisher()
        
        // Save before updating color
        let fx = saveFx.merge(with: audienceFx).eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedAssignNoteColor(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        address: Slashlink,
        color: ThemeColor
    ) -> Update<MemoEditorDetailModel> {
        guard state.address != nil else {
            return Update(state: state)
        }
        
        // Only forward the event if the address matches
        guard state.address == address else {
            return Update(state: state)
        }
        
        var model = state
        model.themeColor = color
            
        return update(
            state: model,
            // Forward success down to meta sheet
            action: .metaSheet(.succeedAssignNoteColor(color)),
            environment: environment
        )
    }
    
    /// Insert wikilink markup into editor, begining at previous range
    /// and wrapping the contents of previous range
    static func insertTaggedMarkup<T>(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        range nsRange: NSRange,
        with withMarkup: (String) -> T
    ) -> Update<MemoEditorDetailModel>
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
        
        return MemoEditorDetailModel.update(
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        return MemoEditorDetailModel.update(
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
    
    func excerpt(fallback: String = "") -> Subtext {
        Subtext.excerpt(markup: self.editor.text, fallback: fallback)
    }
}

// MARK: Outer Model
/// A description of a detail suitible for pushing onto a navigation stack
struct MemoEditorDetailDescription: Hashable {
    var address: Slashlink?
    var fallback: String = ""
    /// Default audience to use when deriving a memo address
    var defaultAudience = Audience.local
}

extension FileFingerprint {
    /// Initialize FileFingerprint from DetailModel.
    /// We use this to do last-write-wins.
    init?(_ detail: MemoEditorDetailModel) {
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
    init?(_ detail: MemoEditorDetailModel) {
        guard let address = detail.address else {
            return nil
        }
        self.address = address
        self.contents = Memo(
            contentType: detail.headers.contentType,
            created: detail.headers.created,
            modified: detail.headers.modified,
            fileExtension: detail.headers.fileExtension,
            themeColor: detail.headers.themeColor,
            additionalHeaders: detail.additionalHeaders,
            body: detail.editor.text
        )
    }
}

struct Detail_Previews: PreviewProvider {
    static var previews: some View {
        MemoEditorDetailView(
            app: Store(state: AppModel(), environment: AppEnvironment()),
            description: MemoEditorDetailDescription(
                address: Slashlink("/nothing-is-lost-in-the-universe")!,
                fallback: "Nothing is lost in the universe"
            ),
            notify: { action in }
        )
    }
}
