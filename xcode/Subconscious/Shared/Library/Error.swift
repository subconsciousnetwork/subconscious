//
//  Error.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/21/23.
//  Common error types

import Foundation

enum CodingError: Error {
    case encodingError(message: String)
    case decodingError(message: String)
}
