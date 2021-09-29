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
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Main (TODO)")
                        Spacer()
                    }
                    Spacer()
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
                                        get: \.editorAttributedText,
                                        tag: AppAction.setEditorAttributedText
                                    ),
                                    isEditorFocused: store.binding(
                                        get: \.isEditorFocused,
                                        tag: AppAction.setEditorFocus
                                    ),
                                    editorSelection: store.binding(
                                        get: \.editorSelection,
                                        tag: AppAction.setEditorSelection
                                    ),
                                    isLinkSheetPresented: store.binding(
                                        get: \.isLinkSheetPresented,
                                        tag: AppAction.setLinkSheetPresented
                                    ),
                                    isLinkSearchFocused: store.binding(
                                        get: \.isLinkSearchFocused,
                                        tag: AppAction.setLinkSearchFocus
                                    ),
                                    linkSearchText: store.binding(
                                        get: \.linkSearchText,
                                        tag: AppAction.setLinkSearchText
                                    ),
                                    linkSuggestions: store.binding(
                                        get: \.linkSuggestions,
                                        tag: AppAction.setLinkSuggestions
                                    ),
                                    backlinks: store.state.backlinks,
                                    onDone: {
                                        store.send(action: .save)
                                    },
                                    onEditorLink: { url, _, range, _ in
                                        store.send(
                                            action: .openEditorURL(
                                                url: url,
                                                range: range
                                            )
                                        )
                                        return false
                                    },
                                    onCommitSearch: { query in
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
                        .navigationBarTitleDisplayMode(.inline)
                    },
                    label: {
                        EmptyView()
                    }
                )
            }
            .navigationTitle("Notes")
            .searchable(
                text: store.binding(
                    get: \.searchBarText,
                    tag: AppAction.setSearch
                ),
                prompt: "Search or create"
            ) {
                ForEach(store.state.suggestions, id: \.self) { suggestion in
                    Button(action: {
                        store.send(
                            action: .commitSearch(suggestion.description)
                        )
                    }) {
                        SuggestionLabelView(suggestion: suggestion)
                    }
                    // We handle submission directly in button action, so
                    // prevent button submit from bubbling up and triggering a
                    // second submit via onSubmit handler.
                    // 2021-09-29 Gordon Brander
                    .submitScope(true)
                }
            }
            // Catch keyboard sumit.
            // This will also catch button activations within `.searchable`
            // suggestions, by default. Therefore, we `.submitScope()` the
            // suggestions so that this only catches keyboard submissions.
            // 2021-09-29 Gordon Brander
            .onSubmit(of: .search, {
                store.send(action: .commitSearch(store.state.searchBarText))
            })
        }
    }
}
