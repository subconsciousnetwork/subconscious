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
public protocol LensProtocol {
    associatedtype OuterState
    associatedtype InnerState

    static func get(state: OuterState) -> InnerState
    static func set(state: OuterState, inner: InnerState) -> OuterState
}

/// TagProtocol defines how to box a value
public protocol TaggableActionProtocol {
    associatedtype OuterAction
    associatedtype InnerAction

    static func tag(action: InnerAction) -> OuterAction
}

/// A cursor combines a lens and a taggable action to provide a complete
/// description of how to map from one component level to another.
public protocol CursorProtocol: LensProtocol, TaggableActionProtocol {}

extension CursorProtocol {
    /// Update state through cursor
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
