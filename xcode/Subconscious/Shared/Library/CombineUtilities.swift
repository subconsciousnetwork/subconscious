//
//  CombineUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation
import Combine

extension Publisher {
    /// Recover from a failure.
    /// Similar to `catch` but allows you to map an `Error` to an `Output`,
    /// without having to wrap in a publisher.
    func recover(
        _ transform: @escaping (Error) -> Output
    ) -> Publishers.Catch<Self, Just<Output>> {
        self.catch({ error in
            Just(transform(error))
        })
    }
}
