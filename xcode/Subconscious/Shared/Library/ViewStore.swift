//
//  ViewStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/12/22.
//

import SwiftUI
import ObservableStore

/// ViewStore is a local projection of a Store that can be passed down to
/// a child view.
///
/// Implementation note: ViewStore works like Binding. It reads state at
/// runtime using a getter closure that you provide. it is important that we
/// read the state via a closure at runtime, like Binding does, rather than
/// passing down the literal value as a property of the instance.
/// If you pass down the literal value as a property, you get "liveness"
/// issues with the data, especially around things like text editors. Letters
/// entered out of order, old states showing up, etc.
/// I suspect this has something to do with either the guts of SwiftUI or the
/// guts of UIViewRepresentable.
/// 2022-06-12 Gordon Brander
struct ViewStore<State, Action> {
    var get: () -> State
    var send: (Action) -> Void
    var state: State { self.get() }

    /// Create a binding that can update the store.
    /// Sets send actions to the store, rather than setting values directly.
    public func binding<Value>(
        get: @escaping (State) -> Value,
        tag: @escaping (Value) -> Action
    ) -> Binding<Value> {
        Binding(
            get: { get(self.state) },
            set: { value in self.send(tag(value)) }
        )
    }

    /// Create a ViewStore from this Store
    func viewStore<LocalState, LocalAction>(
        get: @escaping (State) -> LocalState,
        tag: @escaping (LocalAction) -> Action
    ) -> ViewStore<LocalState, LocalAction> {
        ViewStore<LocalState, LocalAction>(
            get: { get(self.state) },
            send: { action in self.send(tag(action)) }
        )
    }
}

extension Store {
    /// Create a ViewStore from this Store
    func viewStore<LocalState, LocalAction>(
        get: @escaping (State) -> LocalState,
        tag: @escaping (LocalAction) -> Action
    ) -> ViewStore<LocalState, LocalAction> {
        ViewStore(
            get: { get(self.state) },
            send: { action in self.send(tag(action)) }
        )
    }
}

struct Cursor {
    static func update<State, LocalState, Action, LocalAction, Environment>(
        with up: (LocalState, LocalAction, Environment) -> Update<LocalState, LocalAction>,
        get: (State) -> LocalState,
        set: (State, LocalState) -> State,
        tag: @escaping (LocalAction) -> Action,
        state: State,
        action localAction: LocalAction,
        environment: Environment
    ) -> Update<State, Action> {
        let localState = get(state)
        let update = up(localState, localAction, environment)
        let next = set(state, update.state)
        let nextFx = update.fx.map(tag).eraseToAnyPublisher()
        return Update(state: next, fx: nextFx)
    }
}
