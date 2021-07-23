//
//  JSONUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/22/21.
//

import Foundation

extension JSONSerialization {
    /// Serialize Encodable object as JSON string
    static func stringify(
        withJSONObject object: Any,
        options: JSONSerialization.WritingOptions
    ) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: object,
            options: options
        )
        return try String(data: data, encoding: .utf8).unwrap()
    }
}
