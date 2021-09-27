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
                        .transition(.opacity)
                        .zIndex(1)
                    } else {
                        VStack {
                            Spacer()
                            Button(
                                action: {
                                    store.send(
                                        action: .setDetailShowing(true)
                                    )
                                },
                                label: {
                                    Text("Toggle")
                                }
                            )
                            Spacer()
                        }.zIndex(0)
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
                                        tag: AppAction.setEditorFocus,
                                        animation: .easeOut(
                                            duration: Duration.normal
                                        )
                                    ),
                                    editorSelection: store.binding(
                                        get: { state in state.editorSelection },
                                        tag: AppAction.setEditorSelection
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
