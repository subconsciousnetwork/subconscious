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
