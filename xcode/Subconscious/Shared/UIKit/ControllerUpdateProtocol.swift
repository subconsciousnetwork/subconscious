//
//  ControllerModelProtocol.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/22/23.
//

import Foundation
import ObservableStore
import Combine

protocol ControllerUpdateProtocol: UpdateProtocol {
    associatedtype ChangeType
    var changes: [ChangeType] { get set }
}

extension ModelProtocol {
    /// Update state through a sequence of actions, merging fx.
    /// - State updates happen immediately
    /// - Fx are merged
    /// - Last transaction wins
    /// This function is useful for composing actions, or when dispatching
    /// actions down to multiple child components.
    /// - Returns an Update that is the result of sequencing actions
    static func update(
        state: Self,
        actions: [Action],
        environment: Environment
    ) -> UpdateType where UpdateType: ControllerUpdateProtocol {
        var result = UpdateType(state: state)
        for action in actions {
            let next = update(
                state: result.state,
                action: action,
                environment: environment
            )
            result.state = next.state
            result.fx = result.fx.merge(with: next.fx).eraseToAnyPublisher()
            result.transaction = next.transaction
            result.changes.append(contentsOf: next.changes)
        }
        return result
    }
}
