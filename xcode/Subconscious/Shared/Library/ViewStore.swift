//
//  ViewStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/12/22.
//

import SwiftUI
import ObservableStore

/// A "store" is any type that can
/// - get an equatable `state`
/// - `send` actions
public protocol StoreProtocol: Equatable {
    associatedtype State: Equatable
    associatedtype Action

    var state: State { get }

    func send(_ action: Action) -> Void
}

extension StoreProtocol {
    /// Implement equatable for StoreProtocol
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.state == rhs.state
    }
}

/// Implement StoreProtocol for Store
extension Store: StoreProtocol {}

extension Binding {
    /// Initialize a Binding from a store.
    /// - `get` reads the store state to a binding value.
    /// - `tag` transforms the value into an action.
    /// - Returns a binding suitable for use in a vanilla SwiftUI view.
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

/// LensProtocol defines a way to get and set inner values in an outer
/// data container.
public protocol LensProtocol {
    associatedtype OuterState
    associatedtype InnerState

    static func get(state: OuterState) -> InnerState
    static func set(state: OuterState, inner: InnerState) -> OuterState
}

/// TaggableActionProtocol defines a way to box an action for passing
/// between domains.
public protocol TaggableActionProtocol {
    associatedtype OuterAction
    associatedtype InnerAction

    static func tag(_ action: InnerAction) -> OuterAction
}

/// A cursor combines a lens and a taggable action to provide a complete
/// description of how to map from one component domain to another.
public protocol CursorProtocol: LensProtocol, TaggableActionProtocol {}

extension CursorProtocol {
    /// Update an outer state through a cursor.
    /// CursorProtocol.update offers a convenient way to call child
    /// update functions from the parent domain, and get parent-domain
    /// states and actions back from it.
    ///
    /// - `with` the inner update function to use
    /// - `state` the outer state
    /// - `action` the inner action
    /// - `environment` the environment for the update function
    /// - Returns a new outer state
    public static func update<Environment>(
        with update: (
            InnerState,
            InnerAction,
            Environment
        ) -> Update<InnerState, InnerAction>,
        state: OuterState,
        action innerAction: InnerAction,
        environment: Environment
    ) -> Update<OuterState, OuterAction> {
        let next = update(get(state: state), innerAction, environment)
        return Update(
            state: set(state: state, inner: next.state),
            fx: next.fx.map(tag).eraseToAnyPublisher(),
            transaction: next.transaction
        )
    }
}

/// ViewStore is a local projection of a Store that can be passed down to
/// a child view.
///
/// Implementation note: ViewStore works like Binding. It reads state at
/// runtime using a getter closure that you provide. it is important that we
/// read the state via a closure, like Binding does, rather than
/// storing the literal value as a property of the instance.
/// If you store the literal value as a property, you will have "liveness"
/// issues with the data in views, especially around things like text editors.
/// Letters entered out of order, old states showing up, etc.
/// I suspect this has something to do with either the guts of SwiftUI or the
/// guts of UIViewRepresentable.
/// 2022-06-12 Gordon Brander
public struct ViewStore<State, Action>: StoreProtocol, Equatable
where State: Equatable
{
    private let _get: () -> State
    private let _send: (Action) -> Void

    /// Initialize a ViewStore using a get and send closure.
    public init(
        get: @escaping () -> State,
        send: @escaping (Action) -> Void
    ) {
        self._get = get
        self._send = send
    }

    /// Get current state
    public var state: State { self._get() }

    /// Send an action
    public func send(_ action: Action) {
        self._send(action)
    }
}

extension ViewStore {
    /// Initialize a ViewStore from a store of some type, and a get and tag
    /// function.
    /// - Store can be any type conforming to `StoreProtocol`
    /// - `get` and `tag` can be any closure.
    public init<Store: StoreProtocol>(
        store: Store,
        get: @escaping (Store.State) -> State,
        tag: @escaping (Action) -> Store.Action
    ) {
        self.init(
            get: { get(store.state) },
            send: { action in store.send(tag(action)) }
        )
    }

    /// Initialize a ViewStore from a store of some type, and a cursor.
    /// - Store can be any type conforming to `StoreProtocol`
    /// - Cursor can be any type conforming to `CursorProtocol`
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
            get: { Cursor.get(state: store.state) },
            send: { action in store.send(Cursor.tag(action)) }
        )
    }
}

extension ViewStore {
    /// Create a ViewStore for a constant state that swallows actions.
    /// Convenience for view previews.
    public static func constant(
        state: State
    ) -> ViewStore<State, Action> {
        ViewStore<State, Action>(
            get: { state },
            send: { action in }
        )
    }
}
