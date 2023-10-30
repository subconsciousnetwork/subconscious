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

//  MARK: View
struct MemoEditorDetailView: View {
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
        environment: AppEnvironment.default
    )
    /// Is this view presented? Used to detect when back button is pressed.
    /// We trigger an autosave when isPresented is false below.
    @Environment(\.isPresented) var isPresented
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
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
        guard let sub = url.toSubSlashlinkURL() else {
            return true
        }
        
        notify(
            .requestFindLinkDetail(
                Slashlink.ourProfile, // Links in the editor are based from our sphere
                link: sub
            )
        )
        return false
    }
    
    var body: some View {
        VStack {
            if app.state.isBlockEditorEnabled {
                BlockEditor.Representable(
                    state: Binding(
                        get: { store.state.blockEditor },
                        send: store.send,
                        tag: Action.forceSetBlockEditor
                    )
                )
                .frame(
                    minHeight: UIFont.appTextMono.lineHeight * 8
                )
            } else {
                plainEditor()
            }
        }
        .navigationTitle(navigationTitle)
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
            store.send(MemoEditorDetailAction.appear(description))
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(MemoEditorDetailAction.scenePhaseChange(phase))
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
            if self.onLink(url: url) {
                return .handled
            }
            
            return .systemAction
        })
        .onReceive(store.actions) { action in
            MemoEditorDetailAction.logger.debug(
                "\(String(describing: action))"
            )
        }
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
    
    /// Constructs a plain text editor for the view
    private func plainEditor() -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        SubtextTextViewRepresentable(
                            state: store.state.editor,
                            send: Address.forward(
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
                        ThickDividerView()
                            .padding(.bottom, AppTheme.unit4)
                        BacklinksView(
                            backlinks: store.state.backlinks,
                            onRequestDetail: { link in
                                notify(
                                    .requestDetail(
                                        MemoDetailDescription.from(
                                            address: link.address,
                                            fallback: link.title
                                        )
                                    )
                                )
                            },
                            onLink: { address, link in
                                notify(.requestFindLinkDetail(address, link: link))
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

//  MARK: Action

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum MemoEditorDetailNotification: Hashable {
    /// Request specific detail
    case requestDetail(MemoDetailDescription)
    /// Request detail from any audience scope
    case requestFindLinkDetail(
        _ context: Slashlink,
        link: SubSlashlinkLink
    )
    case requestDelete(Slashlink?)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedSaveEntry(address: Slashlink, modified: Date)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
}

extension MemoEditorDetailNotification {
    static func from(_ action: MemoEditorDetailAction) -> Self? {
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
        case .forwardRequestDelete(let address):
            return .requestDelete(address)
        default:
            return nil
        }
    }
}

/// Actions handled by detail's private store.
enum MemoEditorDetailAction: Hashable {
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoEditorDetailAction"
    )

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

    //  Block editor actions
    /// Force set the block editor's state
    case forceSetBlockEditor(BlockEditor.Model)

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
    case setDetail(detail: MemoEditorDetailResponse, autofocus: Bool)
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

    /// Request delete.
    /// Forwards down meta sheet requestDelete, which hides sheet.
    /// Then, after a delay for the bottom sheet animation, sends a
    /// forwardRequestDelete, which is relayed to DetailOuterAction.
    case requestDelete(_ address: Slashlink?)
    /// Action relayed as RequestDelete to DetailOuterAction.
    case forwardRequestDelete(_ address: Slashlink?)

    /// Finish with editing focus
    case doneEditing

    //  Saving entry
    /// Trigger autosave of current state
    case autosave

    //  Give memo an address if it doesn't have one
    case requestAssignAddress
    case assignAddress(Slashlink?)

    /// Save an entry at a particular snapshot value
    case save(MemoEntry?)
    case succeedSave(MemoEntry)
    case failSave(
        address: Slashlink,
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
    case moveEntry(from: Slashlink, to: Slashlink)
    /// Move entry succeeded. Lifecycle action.
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    /// Move entry failed. Lifecycle action.
    case failMoveEntry(String)
    /// Merge entries
    case mergeEntry(parent: Slashlink, child: Slashlink)
    /// Merge entry succeeded. Lifecycle action.
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
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

    static func setMetaSheetAddress(_ address: Slashlink?) -> Self {
        .metaSheet(.setAddress(address))
    }

    static func setMetaSheetDefaultAudience(_ audience: Audience) -> Self {
        .metaSheet(.setDefaultAudience(audience))
    }
}

extension MemoEditorDetailAction {
    static func from(_ suggestion: RenameSuggestion) -> Self {
        switch suggestion {
        case let .move(from, to):
            return .moveEntry(from: from, to: to)
        case let .merge(parent, child):
            return .mergeEntry(parent: parent, child: child)
        }
    }
}

/// React to actions from the root app store
extension MemoEditorDetailAction {
    static func fromAppAction(
        action: AppAction
    ) -> MemoEditorDetailAction? {
        switch (action) {
        case .succeedIndexOurSphere(_),
             .completeIndexPeers:
            return .refreshBacklinks
        case _:
            return nil
        }
    }
}

//  MARK: Cursors
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

struct DetailMetaSheetCursor: CursorProtocol {
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
        case .requestUpdateAudience(let audience):
            return .updateAudience(audience)
        case .requestDelete(let address):
            return .requestDelete(address)
        default:
            return .metaSheet(action)
        }
    }
}

//  MARK: Model
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
    /// Block editor
    var blockEditor = BlockEditor.Model(
        blocks: [
            BlockEditor.BlockModel.heading(
                BlockEditor.TextBlockModel(
                    text: "Autopoiesis"
                )
            ),
            BlockEditor.BlockModel.text(
                BlockEditor.TextBlockModel(
                    text: "The property of a living system (such as a bacterial cell or a multicellular organism) that allows it to maintain and renew itself by regulating its composition and conserving its boundaries.",
                    transcludes: [
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/foo")!,
                            excerpt: Subtext(markup: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization."),
                            isTruncated: true,
                            modified: Date.now
                        ),
                        EntryStub(
                            did: Did("did:key:abc123")!,
                            address: Slashlink("@example/bar")!,
                            excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                            isTruncated: false,
                            modified: Date.now
                        ),
                    ]
                )
            ),
            BlockEditor.BlockModel.quote(
                BlockEditor.TextBlockModel(
                    text: "The notion of autopoiesis is at the core of a shift in perspective about biological phenomena: it expresses that the mechanisms of self-production are the key to understand both the diversity and the uniqueness of the living. (Francisco J. Varela, in Self-Organizing Systems: An Interdisciplinary Approach, 1981)"
                )
            ),
            BlockEditor.BlockModel.list(
                BlockEditor.TextBlockModel(
                    text: "List item"
                )
            ),
            BlockEditor.BlockModel.list(
                BlockEditor.TextBlockModel(
                    text: "List item"
                )
            ),
        ],
        appendix: BlockEditor.RelatedModel(
            related: [
                EntryStub(
                    did: Did("did:key:abc123")!,
                    address: Slashlink("@example/foo")!,
                    excerpt: Subtext(markup: "An autopoietic system is a network of processes that recursively depend on each other for their own generation and realization."),
                    isTruncated: true,
                    modified: Date.now
                ),
                EntryStub(
                    did: Did("did:key:abc123")!,
                    address: Slashlink("@example/bar")!,
                    excerpt: Subtext(markup: "Modularity is a form of hierarchy"),
                    isTruncated: false,
                    modified: Date.now
                ),
                EntryStub(
                    did: Did("did:key:abc123")!,
                    address: Slashlink("@example/baz")!,
                    excerpt: Subtext(markup: "Ashby’s law of requisite variety: If a system is to be stable, the number of states of its control mechanism must be greater than or equal to the number of states in the system being controlled."),
                    isTruncated: true,
                    modified: Date.now
                )
            ]
        )
    )
    
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
    
    //  MARK: Update
    static func update(
        state: MemoEditorDetailModel,
        action: MemoEditorDetailAction,
        environment: AppEnvironment
    ) -> Update<MemoEditorDetailModel> {
        switch action {
        case .metaSheet(let action):
            return DetailMetaSheetCursor.update(
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
        case let .forceSetBlockEditor(blockEditor):
            return forceSetBlockEditor(
                state: state,
                environment: environment,
                blockEditor: blockEditor
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
        case .forwardRequestDelete:
            return Update(state: state)
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
    
    static func forceSetBlockEditor(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        blockEditor: BlockEditor.Model
    ) -> Update<MemoEditorDetailModel> {
        var model = state
        model.blockEditor = blockEditor
        return Update(state: model)
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
        model.isLoading = true
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
        model.isLoading = false
        model.address = detail.entry.address
        model.defaultAudience = detail.entry.address.toAudience()
        model.headers = detail.entry.contents.wellKnownHeaders()
        model.additionalHeaders = detail.entry.contents.additionalHeaders
        model.saveState = detail.saveState
        
        let subtext = detail.entry.contents.body
        let text = String(describing: subtext)
        
        return MemoEditorDetailModel.update(
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        detail: MemoEditorDetailResponse
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        detail: MemoEditorDetailResponse,
        autofocus: Bool
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        defaultAudience: Audience,
        fallback: String
    ) -> Update<MemoEditorDetailModel> {
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
        model.isLoading = true
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
    
    static func updateAudience(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        audience: Audience
    ) -> Update<MemoEditorDetailModel> {
        guard let from = state.address else {
            logger.log(
                "Update audience requested, but no memo is being edited."
            )
            return Update(state: state)
        }

        let to = from.withAudience(audience)

        let fx: Fx<MemoEditorDetailAction> = environment.data.moveEntryPublisher(
            from: from,
            to: to
        ).map({ receipt in
            MemoEditorDetailAction.succeedUpdateAudience(receipt)
        }).catch({ error in
            Just(MemoEditorDetailAction.failUpdateAudience(error.localizedDescription))
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
            // Forrward success down to meta sheet
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
        
        let entry = state.snapshotEntry()
        return update(
            state: state,
            action: .save(entry),
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
                .save(entry),
                .setMetaSheetAddress(address)
            ],
            environment: environment
        )
        .animation(.default)
    }
    
    /// Save snapshot of entry
    static func save(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        entry: MemoEntry?
    ) -> Update<MemoEditorDetailModel> {
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
        
        let fx: Fx<MemoEditorDetailAction> = environment.data.writeEntryPublisher(
            entry
        ).map({ _ in
            MemoEditorDetailAction.succeedSave(entry)
        }).catch({ error in
            Just(
                MemoEditorDetailAction.failSave(
                    address: entry.address,
                    message: error.localizedDescription
                )
            )
        }).eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    /// Log save success and perform refresh of various lists.
    static func succeedSave(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        entry: MemoEntry
    ) -> Update<MemoEditorDetailModel> {
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
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        address: Slashlink,
        message: String
    ) -> Update<MemoEditorDetailModel> {
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
        update(
            state: state,
            actions: [
                // Forward intercepted action down to child
                .metaSheet(.selectRenameSuggestion(suggestion)),
                // Additionally, act on rename suggestion
                MemoEditorDetailAction.from(suggestion)
            ],
            environment: environment
        )
    }

    /// Move entry
    static func moveEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        from: Slashlink,
        to: Slashlink
    ) -> Update<MemoEditorDetailModel> {
        let fx: Fx<MemoEditorDetailAction> = environment.data.moveEntryPublisher(
            from: from,
            to: to
        )
        .map({ _ in
            MemoEditorDetailAction.succeedMoveEntry(from: from, to: to)
        })
        .catch({ error in
            Just(
                MemoEditorDetailAction.failMoveEntry(
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
    
    /// Move failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMoveEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<MemoEditorDetailModel> {
        logger.warning(
            "Failed to move entry with error: \(error)"
        )
        return Update(state: state)
    }
    
    /// Merge entry
    static func mergeEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        parent: Slashlink,
        child: Slashlink
    ) -> Update<MemoEditorDetailModel> {
        let fx: Fx<MemoEditorDetailAction> = environment.data.mergeEntryPublisher(
            parent: parent,
            child: child
        ).map({ _ in
            MemoEditorDetailAction.succeedMergeEntry(parent: parent, child: child)
        }).catch({ error in
            Just(
                MemoEditorDetailAction.failMergeEntry(error.localizedDescription)
            )
        }).eraseToAnyPublisher()
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
    
    /// Merge failure lifecycle handler.
    //  TODO: in future consider triggering an alert.
    static func failMergeEntry(
        state: MemoEditorDetailModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<MemoEditorDetailModel> {
        logger.warning(
            "Failed to merge entry with error: \(error)"
        )
        return Update(state: state)
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

//  MARK: Outer Model
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
