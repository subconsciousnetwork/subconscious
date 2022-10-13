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

    /// Return the result of a closure immediately.
    /// This is useful for working around some of Swift's syntactical
    /// shortcomings. In particular, this lets us treat switch as an
    /// expression that returns a value.
    static func block<T>(_ closure: () -> T) -> T {
        closure()
    }
}
