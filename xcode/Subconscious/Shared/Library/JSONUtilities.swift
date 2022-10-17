//
//  JSONUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/15/22.
//

import Foundation

extension JSONDecoder {
    /// Decode from JSON using a codable type.
    /// Shortcut for instantiating a JSONDecoder and decoding from data.
    static func decode<T>(data: Data, type: T.Type) throws -> T
    where T: Decodable
    {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

extension JSONEncoder {
    /// Encode to JSON using a codable type.
    /// Shortcut for instantiating a JSONEncoder and encoding to data.
    static func encode<T>(_ value: T) throws -> Data
    where T: Encodable
    {
        let encoder = JSONEncoder()
        return try encoder.encode(value)
    }
}
