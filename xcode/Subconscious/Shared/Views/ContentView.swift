//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI

struct ContentView: View {
    @State private var isSearchOpen = false
    @StateObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if !self.isSearchOpen && !store.state.threadQuery.isEmpty {
                    Button(action: {
                        store.send(.query(""))
                        self.isSearchOpen = false
                    }) {
                        Icon(image: Image(systemName: "chevron.left"))
                    }
                }
                SearchBarView(
                    comittedQuery: Binding(
                        get: { store.state.threadQuery },
                        set: { query in
                            store.send(.query(query))
                        }
                    ),
                    liveQuery: Binding(
                        get: { store.state.resultQuery },
                        set: { query in
                            store.send(.searchResults(query: query))
                        }
                    ),
                    isOpen: $isSearchOpen
                )
            }
            .padding(8)
            Divider()
            ZStack {
                if store.state.threadQuery.isEmpty {
                    StreamView()
                } else {
                    SearchView(
                        state: store.state.search,
                        send: address(
                            send: store.send,
                            tag: tagSearchView
                        )
                    )
                }

                PinBottomRight {
                    Button(action: {
                        store.send(.setEditorPresented(true))
                    }) {
                        ActionButton()
                    }
                }

                VStack {
                    if isSearchOpen {
                        ResultListView(
                            results: store.state.results
                        ) { result in
                            store.send(.query(result.text))
                            self.isSearchOpen = false
                        }
                    }
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
                state: store.state.editor,
                send: address(send: store.send, tag: tagEditorView)
            )
        }
    }
}

func tagEditorView(_ action: EditorAction) -> AppAction {
    switch action {
    case .requestEditorUnpresent:
        return .setEditorPresented(false)
    case .requestSave(let thread):
        return .saveThread(thread)
    default:
        return .editor(action)
    }
}

func tagSearchView(_ action: SearchAction) -> AppAction {
    switch action {
    case .requestEdit(let document):
        return .edit(document)
    default:
        return .search(action)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: AppStore(
            state: .init(),
            reducer: appReducer,
            environment: AppEnvironment()
        ))
    }
}
