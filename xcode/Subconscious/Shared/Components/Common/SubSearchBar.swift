//
//  SubSearchBar.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/18/21.
//

import SwiftUI
import Combine

enum SubSearchBarAction {
    case cancel
    case commitQuery(_ query: String)
    case setLiveQuery(_ query: String)
    case setOpen(_ isOpen: Bool)
}

struct SubSearchBarModel: Equatable {
    var comittedQuery = ""
    var liveQuery = ""
    /// Corresponds roughly to active editing mode, but does not necessarily require input to
    /// be focused.
    var isOpen = false
}

func updateSubSearchBar(
    state: inout SubSearchBarModel,
    action: SubSearchBarAction
) -> AnyPublisher<SubSearchBarAction, Never> {
    switch action {
    case .cancel:
        state.liveQuery = state.comittedQuery
        state.isOpen = false
    case .commitQuery(let text):
        state.comittedQuery = text
        state.liveQuery = text
        state.isOpen = false
    case .setLiveQuery(let text):
        state.liveQuery = text
    case .setOpen(let isOpen):
        state.isOpen = isOpen
    }
    return Empty().eraseToAnyPublisher()
}

struct SubSearchBarView: View, Equatable {
    let store: ViewStore<SubSearchBarModel, SubSearchBarAction>
    let placeholder: LocalizedStringKey = "Search"
    let cancel: LocalizedStringKey = "Cancel"

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField(
                    placeholder,
                    text: Binding(
                        get: { store.state.liveQuery },
                        set: { text in store.send(.setLiveQuery(text)) }
                    ),
                    onCommit: {
                        store.send(.commitQuery(store.state.liveQuery))
                    }
                )
                .foregroundColor(.Subconscious.text)
                .transition(.move(edge: .trailing))
                .onTapGesture(perform: {
                    store.send(.setOpen(true))
                })

                if store.state.isOpen && !store.state.liveQuery.isEmpty {
                    Button(action: {
                        store.send(.setLiveQuery(""))
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            .padding(
                EdgeInsets(
                    top: 6,
                    leading: 8,
                    bottom: 6,
                    trailing: 8
                )
            )
            .foregroundColor(Color.Subconscious.secondaryIcon)
            .background(Color.Subconscious.inputBackground)
            .cornerRadius(8.0)
            
            if store.state.isOpen {
                Button(action: {
                    store.send(.cancel)
                }) {
                    Text(cancel)
                }
            }
        }
    }
}

struct SubSearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SubSearchBarView(
                store: ViewStore(
                    state: SubSearchBarModel(),
                    send: { action in }
                )
            )
            SubSearchBarView(
                store: ViewStore(
                    state: SubSearchBarModel(),
                    send: { action in }
                )
            )
        }
    }
}

