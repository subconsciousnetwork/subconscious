//
//  Func.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/18/22.
//

import Foundation

enum RetryError: Error {
    case cancelled
}

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
    
    /// Run the passed throwing async closure, retrying up to `maxAttempts` times.
    /// Will return `nil` if all attempts are used.
    /// Wait time is `2^attempts` seconds capped at `maxWaitSeconds`.
    static func retryWithBackoff<T>(
        maxAttempts: Int,
        maxWaitSeconds: Int = 32,
        attempts: Int = 0,
        _ perform: (_ attempts: Int) async throws -> T
    ) async throws -> T? {
        do {
            return try await perform(attempts)
        } catch RetryError.cancelled {
            return nil
        } catch {
            let attempts = attempts + 1
            guard attempts < maxAttempts else {
                return nil
            }
            
            // capped exponential backoff
            let seconds = UInt32(
                min(
                    Float(maxWaitSeconds),
                    powf(2.0, Float(attempts))
                )
            )
            try await Task.sleep(for: .seconds(seconds))

            return try await self.retryWithBackoff(
                maxAttempts: maxAttempts,
                maxWaitSeconds: maxWaitSeconds,
                attempts: attempts,
                perform
            )
        }
    }
}
