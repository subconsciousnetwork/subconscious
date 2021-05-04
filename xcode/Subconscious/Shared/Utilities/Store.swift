//
//  Store.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/21/21.
//
//  Elm-like state store with effects support.

import Combine
import SwiftUI
import os

typealias Reducer<State, Action, Environment> =
    (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

/// Store holds a single source of truth for your entire app.
/// SwiftUI updates can be driven by using the state variable as an `EnvironmentObject`.
/// Unlike a typical `@Binding`-driven model, you cannot set state directly.
/// Instead, store is udpdated deterministically by using `send` to dispatch actions to a reducer, which
/// is responsible for mutating the state. The same actions result in the same state.
/// Inspired by the [Elm App Architecture](https://guide.elm-lang.org/architecture/).
final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State

    /// Holds references to things like services
    private let environment: Environment
    /// Mutates state in response to an action, returning an effect stream
    private let reducer: Reducer<State, Action, Environment>
    /// Queue of effects to be run
    private var cancellables: Set<AnyCancellable> = []

    init(
        state: State,
        reducer: @escaping Reducer<State, Action, Environment>,
        environment: Environment,
        logger: Logger? = nil
    ) {
        self.state = state
        self.reducer = reducer
        self.environment = environment
    }
    
    func send(_ action: Action) {
        guard let effect = reducer(&state, action, environment) else {
            return
        }
        
        effect
            /// Specifies the schedular used to pull events
            /// <https://developer.apple.com/documentation/combine/fail/receive(on:options:)>
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}

/// Creates a tagged send function that can be used in a sub-view.
/// The returned send function will tag local view actions on the way out.
func address<Action, LocalAction>(
    send: @escaping (Action) -> Void,
    tag: @escaping (LocalAction) -> Action
) -> (LocalAction) -> Void {
    return { localAction in
        send(tag(localAction))
    }
}


/// A generic struct in which you can box actions from lists of items in arrays or dictionaries
struct ItemAction<K, V> {
    var key: K;
    var action: V;
}
