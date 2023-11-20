//
//  ObservableStoreUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/20/23.
//

import Foundation
import ObservableStore

extension Store {
    @MainActor
    func send(onMainActor action: Model.Action) {
        self.send(action)
    }
}
