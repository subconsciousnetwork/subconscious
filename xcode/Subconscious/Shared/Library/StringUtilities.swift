//
//  StringUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/23/21.
//
//  Extensions for String and Substring, plus additional utilities.

import Foundation

extension Substring {
    func toString() -> String {
        String(self)
    }
}

extension String {
    func toSubstring() -> Substring {
        self[...]
    }
}

extension String {
    /// Remove leading `prefix` from string if it exists.
    /// - Returns: new  string without prefix
    func trimming(prefix: String) -> String {
        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        } else {
            return self
        }
    }

    /// Remove trailing `suffix` from string if it exists.
    /// - Returns: new  string without prefix
    func trimming(suffix: String) -> String {
        if self.hasSuffix(suffix) {
            return String(self.dropLast(suffix.count))
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
            substring = substring.dropFirst()
        }
        while substring.last == character {
            substring = substring.dropLast()
        }
        return substring
    }
}

extension String {
    /// Trim string and add blank line ending
    func formattingBlankLineEnding() -> String {
        var trimmed = self.trimmingCharacters(
            in: CharacterSet(charactersIn: "\n ")
        )
        trimmed.append("\n\n")
        return trimmed
    }
}

extension StringProtocol {
    /// Capitalize first letter in string.
    func capitalizingFirst() -> String {
        self.prefix(1).capitalized + self.dropFirst()
    }
}
