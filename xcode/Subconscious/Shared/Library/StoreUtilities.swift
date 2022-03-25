//
//  StoreUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/24/22.
//

import Foundation
import ObservableStore

// TODO: implement these in ObservableStore
extension Update {
    /// Override fx of this update.
    /// - Returns a new Update
    func fx(_ fx: Fx<Action>) -> Update<State, Action> {
        var update = self
        update.fx = fx
        return update
    }

    /// Merge FX with the fx of this update.
    /// - Returns a new Update
    func mergeFx(_ fx: Fx<Action>) -> Update<State, Action> {
        var update = self
        update.fx = update.fx.merge(with: fx).eraseToAnyPublisher()
        return update
    }
}
