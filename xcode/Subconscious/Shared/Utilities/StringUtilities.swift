//
//  StringExtensions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/23/21.
//
import Foundation

extension String {
    /// Remove leading `prefix` from `value` if it exists.
    /// - Returns: new  string without prefix
    func ltrim(prefix: String) -> String {
        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        } else {
            return self
        }
    }
}

extension StringProtocol {
    /// Check if a string contains only whitespace characters
    var isWhitespace: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
