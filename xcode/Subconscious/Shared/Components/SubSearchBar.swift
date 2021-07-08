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
    case setText(_ text: String)
    case commit(_ text: String)
    case setFocus(_ isFocused: Bool)
}

struct SubSearchBarModel: Equatable {
    var text = ""
    var comitted = ""
    var isFocused = false
}

func updateSubSearchBar(
    state: inout SubSearchBarModel,
    action: SubSearchBarAction
) -> AnyPublisher<SubSearchBarAction, Never> {
    switch action {
    case .cancel:
        state.isFocused = false
        state.text = state.comitted
    case .setText(let text):
        state.text = text
    case .commit(let text):
        state.isFocused = false
        state.text = text
        state.comitted = text
    case .setFocus(let isFocused):
        state.isFocused = isFocused
    }
    return Empty().eraseToAnyPublisher()
}

struct SubSearchBarView: View, Equatable {
    let store: ViewStore<SubSearchBarModel, SubSearchBarAction>
    let placeholder: String = "Search or create"

    var body: some View {
        SearchBarRepresentable(
            placeholder: placeholder,
            text: Binding(
                get: { store.state.text  },
                set: { text in store.send(.setText(text)) }
            ),
            onFocus: { store.send(.setFocus(true)) },
            onCommit: { text in store.send(.commit(text)) },
            onCancel: { store.send(.cancel) }
        )
        .focused(store.state.isFocused)
        .showCancel(store.state.isFocused)
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

