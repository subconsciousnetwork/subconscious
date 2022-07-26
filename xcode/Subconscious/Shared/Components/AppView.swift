//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI

//  MARK: View
struct AppView: View {
    @ObservedObject var store: AppStore
    @Environment(\.scenePhase) var scenePhase: ScenePhase
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

                if Config.default.traceryGeistsEnabled {
                    FeedView(store: store)
                } else {
                    AppNavigationView(store: store)
                        .zIndex(1)
                }
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
                        tag: { _ in AppAction.hideSearch }
                    ),
                    content: SearchView(
                        placeholder: "Search or create...",
                        text: store.binding(
                            get: \.searchText,
                            tag: AppAction.setSearch
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: { focus in
                                AppAction.setFocus(
                                    focus: focus,
                                    field: .search
                                )
                            }
                        ),
                        suggestions: store.binding(
                            get: \.suggestions,
                            tag: AppAction.setSuggestions
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
                        tag: { _ in AppAction.hideRenameSheet }
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
                            tag: AppAction.setRenameField
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: { focus in
                                AppAction.setFocus(
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
                        tag: AppAction.setLinkSheetPresented
                    ),
                    height: geometry.size.height,
                    containerSize: geometry.size,
                    content: LinkSearchView(
                        placeholder: "Search or create...",
                        suggestions: store.state.linkSuggestions,
                        text: store.binding(
                            get: \.linkSearchText,
                            tag: AppAction.setLinkSearch
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: { focus in
                                AppAction.setFocus(
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
            .disabled(!store.state.isReadyForInteraction)
            .font(Font(UIFont.appText))
            // Track changes to scene phase so we know when app gets
            // foregrounded/backgrounded.
            // See https://developer.apple.com/documentation/swiftui/scenephase
            // 2022-02-08 Gordon Brander
            .onChange(of: self.scenePhase) { phase in
                store.send(AppAction.scenePhaseChange(phase))
            }
            .onAppear {
                store.send(.appear)
            }
            .environment(\.openURL, OpenURLAction { url in
                store.send(.openURL(url))
                return .handled
            })
        }
    }
}
