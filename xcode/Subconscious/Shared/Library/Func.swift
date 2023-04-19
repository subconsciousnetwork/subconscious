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
    static func run<T>(_ perform: () -> T) -> T {
        perform()
    }
    
    /// Immediately run the passed throwing closure, returning the result.
    /// Useful for wrapping switch statements so they can be treated as expressions.
    static func run<T>(
        _ perform: () throws -> T
    ) throws -> T {
        try perform()
    }
    
    /// Return the result of a closure immediately.
    /// This is useful for working around some of Swift's syntactical
    /// shortcomings. In particular, this lets us treat switch as an
    /// expression that returns a value.
    static func run<T>(_ perform: () async -> T) async -> T {
        await perform()
    }
    
    /// Immediately run the passed throwing closure, returning the result.
    /// Useful for wrapping switch statements so they can be treated as expressions.
    static func run<T>(
        _ perform: () async throws -> T
    ) async throws -> T {
        try await perform()
    }
}
