//
//  Func.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

struct Func {
    static func pipe<T, U>(
        _ value: T,
        through: (T) -> U
    ) -> U {
        through(value)
    }
}
