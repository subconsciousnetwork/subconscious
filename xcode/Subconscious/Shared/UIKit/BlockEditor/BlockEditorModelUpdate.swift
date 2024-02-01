//
//  ModelProtocolUpdateWithChanges.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/20/23.
//
import SwiftUI
import Combine
import ObservableStore

extension BlockEditor {
    struct Update: ControllerUpdateProtocol {
        init(
            state: Model,
            fx: ObservableStore.Fx<Model.Action>,
            transaction: Transaction?
        ) {
            self.state = state
            self.fx = fx
            self.transaction = transaction
        }
        
        init(
            state: Model,
            fx: Fx<Model.Action> = Empty(completeImmediately: true)
                .eraseToAnyPublisher(),
            transaction: Transaction? = nil,
            changes: [BlockEditor.Change] = []
        ) {
            self.state = state
            self.fx = fx
            self.transaction = transaction
            self.changes = changes
        }

        var state: Model
        var fx: Fx<Model.Action>
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
