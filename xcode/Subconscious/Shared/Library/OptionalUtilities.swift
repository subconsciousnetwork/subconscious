//
//  OptionUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/3/21.
//

import Foundation

extension Optional {
    struct NilError: Error {
        let file: String
        let line: Int
        let column: Int
        let function: String
    }
}

extension Optional {
    /// Unwrap an optional, throwing a NilError if nil.
    func unwrap(
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) throws -> Wrapped {
        return try unwrap(
            NilError(
                file: file,
                line: line,
                column: column,
                function: function
            )
        )
    }
}

extension Optional {
    /// Unwrap an optional, throwing an error if nil.
    func unwrap(_ error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            throw error()
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

extension Optional.NilError: LocalizedError {
    public var errorDescription: String? {
        """
        Failed to unwrap nil value (Optional.NilError)
        File: \(self.file)
        Line: \(self.line)
        Column: \(self.column)
        Function: \(self.function)
        """
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
}

extension Optional {
    /// Map an optional value to a different type if it exists,
    /// or else use a fallback value.
    func mapOrElse<T>(
        _ transform: (Wrapped) -> T,
        `default`: () -> T
    ) -> T {
        switch self {
        case .none:
            return `default`()
        case .some(let wrapped):
            return transform(wrapped)
        }
    }
}
