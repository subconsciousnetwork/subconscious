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
            SubSearchBarView(
                store: ViewStore(
                    state: store.state.searchBar,
                    send: store.send,
                    tag: tagSearchBarAction
                )
            ).equatable()

            ZStack {
                VStack(spacing: 0) {
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
                    Spacer()
                    HStack {
                        Button(
                            action: {
                                store.send(.commitQuery(""))
                            },
                            label: {
                                Icon(image: Image(systemName: "chevron.left"))
                            }
                        )
                        .disabled(store.state.searchBar.comitted.isEmpty)
                        // We pad 8pt .leading to match UISearchView's
                        // 8pt .leading padding.
                        .padding(.leading, 8)
                        Spacer()
                    }
                }

                Group {
                    SuggestionsView(
                        store: ViewStore(
                            state: store.state.suggestions,
                            send: store.send,
                            tag: tagSuggestionsAction
                        )
                    )
                    .equatable()
                    .animation(.none)
                }
                .background(Color.Sub.background)
                .opacity(store.state.searchBar.isFocused ? 1 : 0)
                .transition(.opacity)
                .animation(.easeOut(duration: SubConstants.Duration.fast))
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
