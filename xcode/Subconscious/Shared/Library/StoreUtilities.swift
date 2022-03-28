//
//  StoreUtilities.swift
//  SubconsciousSandbox
//
//  Created by Gordon Brander on 3/23/22.
//

import Foundation
import ObservableStore

extension Update {
    /// Map an update for a local scope
    /// into an update for a broader scope.
    static func scope<LocalState, LocalAction>(
        update: Update<LocalState, LocalAction>,
        state: State,
        set: (State, LocalState) -> State,
        tag: @escaping (LocalAction) -> Action
    ) -> Update<State, Action> {
        Update(
            state: set(state, update.state),
            fx: update.fx.map(tag).eraseToAnyPublisher(),
            transaction: update.transaction
        )
    }
}

/// ViewStore provides access to a read-only state and a send function.
struct ViewStore<State, Action>: Equatable
where State: Equatable {
    static func == (
        lhs: ViewStore<State, Action>,
        rhs: ViewStore<State, Action>
    ) -> Bool {
        lhs.state == rhs.state
    }

    let state: State
    let send: (Action) -> Void

    /// Create a localized ViewStore from this ViewStore
    func viewStore<LocalState, LocalAction>(
        get: (State) -> LocalState,
        tag: @escaping (LocalAction) -> Action
    ) -> ViewStore<LocalState, LocalAction> {
        ViewStore<LocalState, LocalAction>(
            state: get(self.state),
            send: { local in self.send(tag(local)) }
        )
    }
}

extension Store {
    /// Create a localized `ViewStore` from this store
    func viewStore<LocalState, LocalAction>(
        get: (State) -> LocalState,
        tag: @escaping (LocalAction) -> Action
    ) -> ViewStore<LocalState, LocalAction> {
        ViewStore(
            state: get(self.state),
            send: { local in self.send(tag(local)) }
        )
    }
}
