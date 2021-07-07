//
//  StringExtensions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/23/21.
//
import Foundation

struct StringUtilities {
    /// Remove leading `prefix` from `value` if it exists.
    /// - Returns: modified string
    static func ltrim(prefix: String, value: String) -> String {
        if value.hasPrefix(prefix) {
            return String(value.dropFirst(prefix.count))
        } else {
            return value
        }
    }
}

extension StringProtocol {
    /// Check if a string contains only whitespace characters
    var isWhitespace: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
