//
//  StringExtensions.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/23/21.
//
import Foundation

/// Remove leading `prefix` from `value` if it exists.
/// - Returns: modified string
func ltrim(prefix: String, value: String) -> String {
    if value.hasPrefix(prefix) {
        return String(value.dropFirst(prefix.count))
    } else {
        return value
    }
}
