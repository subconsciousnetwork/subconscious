//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    @ObservedObject var store: Store<AppModel>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    if store.state.isSearchBarFocused {
                        SuggestionsView(
                            suggestions: store.state.suggestions,
                            action: { suggestion in
                                store.send(
                                    action: .commitSearch(suggestion.description)
                                )
                            }
                        )
                        .zIndex(1)
                    } else {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("Main (TODO)")
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color.secondaryBackground)
                        .zIndex(0)
                    }
                }
                NavigationLink(
                    isActive: store.binding(
                        get: \.isDetailShowing,
                        tag: AppAction.setDetailShowing
                    ),
                    destination: {
                        VStack {
                            if store.state.entryURL == nil {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                DetailView(
                                    editorAttributedText: store.binding(
                                        get: { state in
                                            state.editorAttributedText
                                        },
                                        tag: AppAction.setEditorAttributedText
                                    ),
                                    isEditorFocused: store.binding(
                                        get: { state in
                                            state.isEditorFocused
                                        },
                                        tag: AppAction.setEditorFocus
                                    ),
                                    editorSelection: store.binding(
                                        get: { state in state.editorSelection },
                                        tag: AppAction.setEditorSelection
                                    ),
                                    isLinkSheetPresented: store.binding(
                                        get: { state in
                                            state.isLinkSheetPresented
                                        },
                                        tag: AppAction.setLinkSheetPresented
                                    ),
                                    isLinkSearchFocused: store.binding(
                                        get: { state in
                                            state.isLinkSearchFocused
                                        },
                                        tag: AppAction.setLinkSearchFocus
                                    ),
                                    linkSearchText: store.binding(
                                        get: { state in state.linkSearchText },
                                        tag: AppAction.setLinkSearchText
                                    ),
                                    linkSuggestions: store.binding(
                                        get: { store in store.linkSuggestions },
                                        tag: AppAction.setLinkSuggestions
                                    ),
                                    backlinks: store.state.backlinks,
                                    onDone: {
                                        store.send(action: .save)
                                    },
                                    onEditorLink: { url, _, range, interaction in
                                        store.send(
                                            action: .openEditorURL(
                                                url: url,
                                                range: range
                                            )
                                        )
                                        return false
                                    },
                                    onActivateBacklink: { query in
                                        store.send(
                                            action: .commitSearch(query)
                                        )
                                    },
                                    onCommitLinkSearch: { query in
                                        store.send(
                                            action: .commitLinkSearch(query)
                                        )
                                    }
                                )
                            }
                        }
                        .navigationTitle("")
                    },
                    label: {
                        EmptyView()
                    }
                )
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBarRepresentable(
                        placeholder: "Search or create",
                        text: store.binding(
                            get: { state in state.searchBarText },
                            tag: AppAction.setSearch
                        ),
                        isFocused: store.binding(
                            get: { state in state.isSearchBarFocused },
                            tag: AppAction.setSearchBarFocus,
                            animation: .easeOut(duration: Duration.normal)
                        ),
                        onCommit: { text in
                            store.send(action: .commitSearch(text))
                        },
                        onCancel: {}
                    ).showCancel(true)
                }
            }
        }
    }
}
