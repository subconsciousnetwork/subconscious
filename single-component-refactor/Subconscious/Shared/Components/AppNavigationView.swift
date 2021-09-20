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
                VStack(spacing: 0) {
                    if store.state.isSearchBarFocused {
                        SuggestionsView(
                            suggestions: store.state.suggestions,
                            action: { suggestion in
                                store.send(
                                    action: .commitSearch(suggestion.description)
                                )
                            }
                        )
                    } else {
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
                    }
                }
                NavigationLink(
                    isActive: Binding(
                        get: { store.state.isDetailShowing },
                        set: { value in
                            store.send(
                                action: .setDetailShowing(value)
                            )
                        }
                    ),
                    destination: {
                        VStack {
                            if store.state.isDetailLoading {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                DetailView(
                                    editor: store.binding(
                                        get: { store in
                                            store.editor
                                        },
                                        tag: { value in
                                            .setEditor(value)
                                        }
                                    ),
                                    backlinks: store.state.backlinks,
                                    onBacklinkTap: { query in
                                        store.send(
                                            action: .commitSearch(query)
                                        )
                                    }
                                )
                            }
                        }
                        .navigationTitle(store.state.query)
                    },
                    label: {
                        EmptyView()
                    }
                )
            }
            .navigationTitle("Home")
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
                            tag: AppAction.setSearchBarFocus
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
