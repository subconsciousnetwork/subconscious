//
//  ObservableStoreUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/14/22.
//

import Foundation
import ObservableStore

extension ModelProtocol {
    static func update(
        state: Self,
        actions: [Action],
        environment: Environment
    ) -> Update<Self> {
        actions.reduce(
            Update(state: state),
            { result, action in
                let next = update(
                    state: state,
                    action: action,
                    environment: environment
                )
                return Update(
                    state: next.state,
                    fx: result.fx.merge(with: next.fx).eraseToAnyPublisher(),
                    transaction: next.transaction
                )
            }
        )
    }
}
