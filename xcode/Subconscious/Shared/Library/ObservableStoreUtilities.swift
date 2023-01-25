//
//  ObservableStoreUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/23.
//

import Foundation
import ObservableStore

extension Store {
    convenience init(
        state: Model,
        action: Model.Action,
        environment: Model.Environment
    ) {
        self.init(state: state, environment: environment)
        self.send(action)
    }
}
