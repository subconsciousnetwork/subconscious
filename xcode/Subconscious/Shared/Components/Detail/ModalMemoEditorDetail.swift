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
struct ModalMemoEditorDetailView: View {
    typealias Action = MemoEditorDetailAction
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<MemoEditorDetailModel>

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
        guard let link = url.toSubSlashlinkLink()?.toEntryLink() else {
            return true
        }
        notify(.requestFindLinkDetail(link))
        return false
    }
    
    var body: some View {
        VStack {
            plainEditor()
        }
        .onAppear {
            // When an editor is presented, refresh if stale.
            // This covers the case where the editor might have been in the
            // background for a while, and the content changed in another tab.
            store.send(MemoEditorDetailAction.appear(description))
        }
        .onDisappear {
            store.send(MemoEditorDetailAction.disappear)
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { _, phase in
            store.send(.scenePhaseChange(phase))
        }
        // Save when back button pressed.
        // Note that .onDisappear is too late, because by the time the save
        // succeeds, the store for this view is already thrown away, so
        // we never receive the save-succeeded action.
        // Reacting to isPresented is soon enough.
        // 2023-02-14
        .onChange(of: self.isPresented) { _, isPresented in
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
    
    

    /// Constructs a plain text editor for the view
    private func plainEditor() -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        VStack {
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
                                    top: 0,
                                    leading: AppTheme.padding,
                                    bottom: AppTheme.padding,
                                    trailing: AppTheme.padding
                                )
                            )
                        }
                    }
                }
                .background(store.state.background)
                .tint(store.state.highlight)
                
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
                        },
                        background: store.state.themeColor?.toColor() 
                            ?? store.state.address?.themeColor.toColor()
                            ?? .background,
                        color: store.state.themeColor?.toHighlightColor()
                            ?? store.state.address?.themeColor.toHighlightColor()
                            ?? .accentColor
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
