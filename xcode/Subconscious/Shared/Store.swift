//
//  Store.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/21/21.
//
//  Elm-like state store with effects support.

import Combine
import SwiftUI

typealias Effect<Action> = AnyPublisher<Action, Never>

typealias Reducer<State, Action, Environment> =
    (inout State, Action, Environment) -> Effect<Action>?

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
        environment: Environment
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

extension Store {
    /// Derives a binding from the store that prevents direct writes to state and instead sends
    /// actions to the store.
    ///
    /// Inspired by:
    /// <https://github.com/pointfreeco/swift-composable-architecture/blob/1d1ce31471f7cf74179e9945138883a2137aabb4/Sources/ComposableArchitecture/ViewStore.swift>
    ///
    /// The method is useful for dealing with SwiftUI components that work with two-way `Binding`s
    /// since the `Store` does not allow directly writing its state; it only allows reading state and
    /// sending actions.
    ///
    /// For example, a text field binding can be created like this:
    ///
    ///     struct State { var name = "" }
    ///     enum Action { case nameChanged(String) }
    ///
    ///     TextField(
    ///       "Enter name",
    ///       text: viewStore.binding(
    ///         get: { $0.name },
    ///         send: { Action.nameChanged($0) }
    ///       )
    ///     )
    ///
    /// - Parameters:
    ///   - get: A function to get the state for the binding from the view
    ///     store's full state.
    ///   - localStateToViewAction: A function that transforms the binding's value
    ///     into an action that can be sent to the store.
    /// - Returns: A binding.
    func binding<LocalState>(
        get: @escaping (State) -> LocalState,
        send localStateToViewAction: @escaping (LocalState) -> Action
    ) -> Binding<LocalState> {
        Binding(
            get: { get(self.state) },
            set: { newLocalState, transaction in
                if transaction.animation != nil {
                    withTransaction(transaction) {
                        self.send(localStateToViewAction(newLocalState))
                    }
                } else {
                    self.send(localStateToViewAction(newLocalState))
                }
            }
        )
    }
}
