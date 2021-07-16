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
            Divider()
            ZStack {
                VStack(spacing: 0) {
                    if store.state.searchBar.comitted.isEmpty {
                        StreamView().equatable()
                    } else {
                        EntryListView(
                            store: ViewStore(
                                state: store.state.search,
                                send: store.send,
                                tag: tagSearchAction
                            )
                        ).equatable()
                    }
                    Divider()
                    HStack(spacing: 16) {
                        Button(
                            action: {
                                store.send(.commitQuery(""))
                            },
                            label: {
                                IconView(image: Image(systemName: "chevron.left"))
                            }
                        )
                        .disabled(store.state.searchBar.comitted.isEmpty)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
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
