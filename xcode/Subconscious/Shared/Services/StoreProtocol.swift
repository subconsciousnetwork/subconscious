//
//  StoreProtocol.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/2/22.
//

import Foundation

protocol StoreProtocol {
    func read(_ key: String) -> Data?
    func write(_ key: String, value: Data) throws
    func remove(_ key: String) throws
    func info(_ key: String) -> FileInfo?
    func save() throws
    func list() throws -> [String]
}

enum StoreProtocolError: Error {
    case decodingError
    case encodingError
}

extension StoreProtocol {    
    /// Write with a failable encoding function
    /// Our codebase defines a number of `DataType.from` static methods
    /// that can be composed to encode the data type you need.
    func write<T>(
        with encode: (T) -> Data?,
        key: String,
        value: T
    ) throws {
        guard let encoded = encode(value) else {
            throw StoreProtocolError.encodingError
        }
        try write(key, value: encoded)
    }

    /// Get filtered list of keys for this domain
    func list(_ isIncluded: (String) -> Bool) throws -> [String] {
        try list().filter(isIncluded)
    }
}
