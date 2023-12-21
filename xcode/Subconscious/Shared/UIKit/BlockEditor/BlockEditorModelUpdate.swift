//
//  ModelProtocolUpdateWithChanges.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/20/23.
//
import SwiftUI
import Combine
import ObservableStore

extension BlockEditor.Model {
    struct Update: UpdateProtocol {
        init(
            state: BlockEditor.Model,
            fx: ObservableStore.Fx<BlockEditor.Action>,
            transaction: Transaction?
        ) {
            self.state = state
            self.fx = fx
            self.transaction = transaction
        }
        
        init(
            state: BlockEditor.Model,
            fx: Fx<BlockEditor.Action> = Empty(completeImmediately: true)
                .eraseToAnyPublisher(),
            transaction: Transaction? = nil,
            changes: [BlockEditor.Change] = []
        ) {
            self.state = state
            self.fx = fx
            self.transaction = transaction
            self.changes = changes
        }
        
        var state: BlockEditor.Model
        var fx: Fx<Action>
        var transaction: Transaction?
        /// Changes are commands sent to the controller
        var changes: [BlockEditor.Change] = []

        /// Add additional changes to this update
        func appendingChanges(_ changes: [BlockEditor.Change]) -> Self {
            var this = self
            this.changes.append(contentsOf: changes)
            return this
        }
    }
}

extension ModelProtocol where UpdateType == BlockEditor.Model.Update {
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
    ) -> UpdateType {
        var result = BlockEditor.Model.Update(state: state)
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
