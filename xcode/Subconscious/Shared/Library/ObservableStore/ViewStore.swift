//
//  ViewStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/12/22.
//

import SwiftUI
import ObservableStore

public protocol StoreProtocol {
    associatedtype State
    associatedtype Action

    var state: State { get }

    func send(_ action: Action) -> Void
}

/// Implement StoreProtocol for Store
extension Store: StoreProtocol {}

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
public struct ViewStore<State, Action>: StoreProtocol {
    private let _get: () -> State
    private let _send: (Action) -> Void

    public init(
        get: @escaping () -> State,
        send: @escaping (Action) -> Void
    ) {
        self._get = get
        self._send = send
    }

    public init<Store: StoreProtocol>(
        store: Store,
        get: @escaping (Store.State) -> State,
        tag: @escaping (Action) -> Store.Action
    ) {
        self.init(
            get: {
                get(store.state)
            },
            send: { action in
                store.send(tag(action))
            }
        )
    }

    public init<Store, Cursor>(store: Store, cursor: Cursor.Type)
    where
        Store: StoreProtocol,
        Cursor: CursorProtocol,
        Store.State == Cursor.OuterState,
        Store.Action == Cursor.OuterAction,
        State == Cursor.InnerState,
        Action == Cursor.InnerAction
    {
        self.init(
            get: {
                Cursor.get(state: store.state)
            },
            send: { action in
                store.send(Cursor.tag(action: action))
            }
        )
    }

    public var state: State { self._get() }

    public func send(_ action: Action) {
        self._send(action)
    }

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

extension Binding {
    init<Store: StoreProtocol>(
        store: Store,
        get: @escaping (Store.State) -> Value,
        tag: @escaping (Value) -> Store.Action
    ) {
        self.init(
            get: { get(store.state) },
            set: { value in store.send(tag(value)) }
        )
    }
}

extension ViewStore {
    public static func constant(
        state: State
    ) -> ViewStore<State, Action> {
        ViewStore<State, Action>(
            get: { state },
            send: { action in }
        )
    }
}
