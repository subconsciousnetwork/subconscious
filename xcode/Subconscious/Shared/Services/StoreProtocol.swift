//
//  StoreProtocol.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/2/22.
//

import Foundation

protocol StoreProtocol {
    associatedtype Key
    associatedtype Value
    associatedtype Keys: Sequence where Keys.Element == Key
    func read(_ key: Key) throws -> Value
    func write(_ key: Key, value: Value) throws
    func remove(_ key: Key) throws
    func save() throws
    func list() throws -> Keys
}

enum StoreProtocolError: Error {
    case decodingError
    case encodingError
}

extension StoreProtocol {
    /// Read with a failable decoding function
    /// Our codebase defines a number of `DataType.from` static methods
    /// that can be composed to decode the data type you need.
    func read<T>(
        with decode: (Value) -> T?,
        key: Key
    ) throws -> T {
        let data: Value = try read(key)
        guard let decoded = decode(data) else {
            throw StoreProtocolError.decodingError
        }
        return decoded
    }
    
    /// Write with a failable encoding function
    /// Our codebase defines a number of `DataType.from` static methods
    /// that can be composed to encode the data type you need.
    func write<T>(
        with encode: (T) -> Value?,
        key: Key,
        value: T
    ) throws {
        guard let encoded: Value = encode(value) else {
            throw StoreProtocolError.encodingError
        }
        try write(key, value: encoded)
    }

    /// Get filtered list of keys for this domain
    func list(_ isIncluded: (Key) -> Bool) throws -> [Key] {
        try list().filter(isIncluded)
    }
}

