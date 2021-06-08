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

    /// Unwrap an optional, throwing a NilError if nil.
    func unwrap(
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) throws -> Wrapped {
        return try unwrap(
            or: NilError(
                file: file,
                line: line,
                column: column,
                function: function
            )
        )
    }

    /// Unwrap an optional, throwing an error if nil.
    func unwrap(or error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            throw error()
        }
    }
}
