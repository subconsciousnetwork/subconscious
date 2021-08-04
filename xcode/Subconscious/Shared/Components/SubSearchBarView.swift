//
//  SubSearchBar.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/18/21.
//

import SwiftUI
import Combine
import Elmo
import os

enum SubSearchBarAction {
    case cancel
    case setText(String)
    case commit(String)
    case commitSuccess(String)
    case commitFailure(message: String)
    case setFocus(_ isFocused: Bool)
}

struct SubSearchBarModel: Equatable {
    var text = ""
    var comitted = ""
    var isFocused = false
}

func updateSubSearchBar(
    state: inout SubSearchBarModel,
    action: SubSearchBarAction,
    environment: IOService
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
        return environment.database.insertSearchHistory(query: text)
            .map({ query in
                .commitSuccess(query)
            })
            .catch({ error in
                Just(.commitFailure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .commitSuccess(let query):
        environment.logger.log("Inserted search history: \(query)")
    case .commitFailure(let message):
        environment.logger.warning("\(message)")
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
            onFocus: {
                withAnimation {
                    store.send(.setFocus(true))
                }
            },
            onCommit: { text in store.send(.commit(text)) },
            onCancel: {
                withAnimation {
                    store.send(.cancel)
                }
            }
        )
        .focused(store.state.isFocused)
        .showCancel(store.state.isFocused)
    }
}

struct SubSearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
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

