//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore;
    @State private var isEditPresented: Bool = false
    @State private var isSearchOpen = true
    @State private var editorText = ""
    @State private var editorTitle = ""

    func invokeEdit(title: String, text: String) {
        self.isEditPresented = true
        self.editorTitle = title
        self.editorText = text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if !self.isSearchOpen && !store.state.threadQuery.isEmpty {
                    Button(action: {
                        store.send(AppAction.search(query: ""))
                        self.isSearchOpen = false
                    }) {
                        Icon(image: Image(systemName: "chevron.left"))
                    }
                }
                SearchBarView(
                    comittedQuery: store.binding(
                        get: { state in state.threadQuery },
                        send: { query in AppAction.search(query: query) }
                    ),
                    liveQuery: store.binding(
                        get: { state in state.resultQuery },
                        send: { query in AppAction.searchResults(query: query) }
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
                        threads: store.state.threads
                    )
                }

                PinBottomRight {
                    Button(action: {
                        self.invokeEdit(
                            title: "",
                            text: ""
                        )
                    }) {
                        ActionButton()
                    }
                }

                VStack {
                    if isSearchOpen {
                        ResultListView(
                            results: store.state.results
                        ) { result in
                            store.send(
                                AppAction.search(query: result.text)
                            )
                            self.isSearchOpen = false
                        }
                    }
                }
            }
        }
        .onAppear {
            store.send(.appear)
        }
        .sheet(isPresented: $isEditPresented) {
            Editor(
                title: $editorTitle,
                text: $editorText,
                isPresented: $isEditPresented
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppStore(
            state: .init(),
            reducer: appReducer,
            environment: AppEnvironment()
        ))
    }
}
