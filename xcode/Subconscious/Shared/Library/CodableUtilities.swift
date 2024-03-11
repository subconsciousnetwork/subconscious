//
//  CodableUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/11/24.
//

import Foundation

extension JSONEncoder {
    /// Encode JSON to a UTF-8 string
    func stringify<T: Encodable>(_ encodable: T) throws -> String {
        let data = try encode(encodable)
        return String(decoding: data, as: UTF8.self)
    }
}

extension JSONDecoder {
    /// Decode JSON from a UTF-8 string
    func parse<T: Decodable>(
        _ type: T.Type,
        string: String
    ) throws -> T {
        try decode(type, from: Data(string.utf8))
    }
}
