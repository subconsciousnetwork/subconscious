//
//  StringUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/23/21.
//
//  Extensions for String and Substring, plus additional utilities.

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

extension String {
    func splitlines() -> [Substring] {
        self.split(
            maxSplits: Int.max,
            omittingEmptySubsequences: true,
            whereSeparator: \.isNewline
        )
    }
}

extension StringProtocol {
    /// Check if a string contains only whitespace characters
    var isWhitespace: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Substring {
    var range: Range<Substring.Index> {
        self.startIndex..<self.endIndex
    }
}

extension Substring {
    // Implement trim for substring
    func trimming(_ character: Character) -> Substring {
        var substring = self
        while substring.first == character {
            let _ = substring.popFirst()
        }
        while substring.last == character {
            let _ = substring.popLast()
        }
        return substring
    }
}

extension String {
    func replacingNewlineWithSpace() -> String {
        self.replacingOccurrences(
            of: "\\s",
            with: " ",
            options: .regularExpression
        )
    }
}
