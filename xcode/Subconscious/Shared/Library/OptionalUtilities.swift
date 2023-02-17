//
//  OptionUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/3/21.
//

import Foundation

enum UnwrapError: Error, LocalizedError {
    case nilError
    
    var errorDescription: String? {
        switch self {
        case .nilError:
            return "Failed to unwrap value"
        }
    }
}

extension Optional {
    /// Unwrap an optional, throwing an error if nil.
    func unwrap(_ error: Error = UnwrapError.nilError) throws -> Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            throw error
        }
    }
}

extension Optional {
    /// Unwrap an optional, returning a fallback value if nil.
    func unwrap(or fallback: Wrapped) -> Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            return fallback
        }
    }
}

extension Optional {
    /// Map an optional value to a different type if it exists,
    /// or else use a fallback value.
    func mapOr<T>(
        _ transform: (Wrapped) -> T,
        `default`: T
    ) -> T {
        switch self {
        case .none:
            return `default`
        case .some(let wrapped):
            return transform(wrapped)
        }
    }
    
    /// Map an optional value with a transforming function that returns
    /// an optional result. In case of none, returns default.
    func compactMapOr<T>(
        _ transform: (Wrapped) -> T?,
        `default`: T
    ) -> T {
        switch self {
        case .none:
            return `default`
        case .some(let wrapped):
            return transform(wrapped) ?? `default`
        }
    }
}
