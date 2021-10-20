//
//  RandomString.swift
//  Subconscious
//
//  Created by Gordon Brander on 10/7/21.
//

import Foundation

extension String {
    private static let alphanumeric = "abcdefghijklmnopqrstuvwxyz0123456789"

    /// Generate a string of alphanumeric characters of length
    static func randomAlphanumeric(length: Int = 8) -> String {
        var string = ""
        for _ in 0..<length {
            let char = alphanumeric.randomElement()!
            string.append(char)
        }
        return string
    }
}
