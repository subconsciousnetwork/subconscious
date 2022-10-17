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

precedencegroup PipeOperator {
    associativity: left
}

infix operator |>: PipeOperator

/// Pipe a value through functions
func |> <A, B>(lhs: A, rhs: (A) -> B) -> B {
    rhs(lhs)
}

/// Pipe a value through a throwing function
func |> <A, B>(lhs: A, rhs: (A) throws -> B) throws -> B {
    try rhs(lhs)
}

/// Pipe an optional value through an optional mapping function
func |> <A, B>(lhs: A?, rhs: (A) -> B?) -> B? {
    guard let value = lhs else {
        return nil
    }
    return rhs(value)
}
