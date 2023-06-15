//
//  Error.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/21/23.
//  Common error types

import Foundation

enum CodingError: Error, LocalizedError {
    case encodingError(message: String)
    case decodingError(message: String)
    
    var errorDescription: String? {
        switch self {
        case let .encodingError(message):
            return "Encoding failed: \(message)"
        case let .decodingError(message):
            return "Decoding failed: \(message)"
        }
    }
}

/// Thrown when a value provided is not valid
struct ValueError:
    Error,
    LocalizedError,
    Hashable,
    Codable,
    CustomStringConvertible
{
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
    
    var errorDescription: String? {
        "Value error: \(description)"
    }
}
