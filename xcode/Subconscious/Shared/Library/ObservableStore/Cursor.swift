//
//  Cursor.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/1/22.
//

import Foundation
import ObservableStore

/// LensProtocol defines a way to get and set inner values in an outer
/// data container.
protocol LensProtocol {
    associatedtype OuterState
    associatedtype InnerState

    static func get(state: OuterState) -> InnerState
    static func set(state: OuterState, inner: InnerState) -> OuterState
}

/// TagProtocol defines how to box a value
protocol TaggableActionProtocol {
    associatedtype OuterAction
    associatedtype InnerAction

    static func tag(action: InnerAction) -> OuterAction
}

/// A cursor combines a lens and a taggable action to provide a complete
/// description of how to map from one component level to another.
protocol CursorProtocol: LensProtocol, TaggableActionProtocol {}

extension CursorProtocol {
    /// Update state through cursor
    static func update<Environment>(
        with update: (InnerState, InnerAction, Environment) -> Update<InnerState, InnerAction>,
        state: OuterState,
        action innerAction: InnerAction,
        environment: Environment
    ) -> Update<OuterState, OuterAction> {
        let innerState = get(state: state)
        let up = update(innerState, innerAction, environment)
        let nextState = set(state: state, inner: up.state)
        let nextFx = up.fx.map(tag).eraseToAnyPublisher()
        return Update(state: nextState, fx: nextFx)
    }
}
