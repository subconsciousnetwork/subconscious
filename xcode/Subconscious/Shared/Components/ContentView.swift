//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI
import Foundation
import Combine
import os

struct ContentView: View, Equatable {
    var store: ViewStore<AppModel, AppAction>

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if (
                    !store.state.searchBar.isFocused &&
                    !store.state.searchBar.comitted.isEmpty
                ) {
                    Button(
                        action: {
                            store.send(.commitQuery(""))
                        },
                        label: {
                            Icon(image: Image(systemName: "chevron.left"))
                        }
                    )
                    // We pad 8pt .leading to match UISearchView's
                    // 8pt .leading padding.
                    .padding(.leading, 8)
                }
                SubSearchBarView(
                    store: ViewStore(
                        state: store.state.searchBar,
                        send: store.send,
                        tag: tagSearchBarAction
                    )
                ).equatable()
            }

            ZStack {
                if store.state.searchBar.comitted.isEmpty {
                    StreamView().equatable()
                } else {
                    SearchView(
                        store: ViewStore(
                            state: store.state.search,
                            send: store.send,
                            tag: tagSearchAction
                        )
                    ).equatable()
                }

                PinBottomRight {
                    Button(action: {
                        store.send(.setEditorPresented(true))
                    }) {
                        ActionButton()
                    }
                }

                if store.state.searchBar.isFocused {
                    ScrollView {
                        VStack(spacing: 0) {
                            if (store.state.searchBar.text.isEmpty) {
                                TextTokenBarView(
                                    store: ViewStore(
                                        state: store.state.suggestionTokens,
                                        send: store.send,
                                        tag: tagSuggestionTokensAction
                                    )
                                )
                                .equatable()
                                .padding(.top, 0)
                                // We pad by 10pt to match UISearchBar's
                                // 10pt padding
                                .padding(.bottom, 10)
                            }
                            Divider()
                            SuggestionsView(
                                store: ViewStore(
                                    state: store.state.suggestions,
                                    send: store.send,
                                    tag: tagSuggestionListAction
                                )
                            ).equatable()
                        }
                    }
                    .background(Color.Subconscious.background)
                }
            }
        }
        .onAppear {
            store.send(.appear)
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isEditorPresented },
                set: { isPresented in
                    store.send(.setEditorPresented(isPresented))
                }
            )
        ) {
            EditorView(
                store: ViewStore(
                    state: store.state.editor,
                    send: store.send,
                    tag: tagEditorAction
                )
            ).equatable()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(
            state: .init(),
            reducer: updateApp,
            environment: .init()
        )

        return ContentView(
            store: ViewStore(
                state: store.state,
                send: store.send
            )
        )
    }
}
