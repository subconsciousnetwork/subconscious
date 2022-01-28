//
//  StringUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/23/21.
//
//  Extensions for String and Substring, plus additional utilities.

import Foundation

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
            substring = substring.dropFirst()
        }
        while substring.last == character {
            substring = substring.dropLast()
        }
        return substring
    }
}

extension String {
    /// Returns a string path with the path extension removed, if any.
    /// Extension is anything after the first `.`.
    func deletingPathExtension() -> String {
        if let stem = self.split(separator: ".").first {
            return String(stem)
        }
        return self
    }
}

extension String {
    /// Truncate to avoid file name length limit issues.
    /// Windows systems can handle up to 255, but we truncate at 200 to leave a bit of room
    /// for things like version numbers.
    func truncatingSafeFileNameLength() -> String {
        String(self.prefix(200))
    }
}

extension StringProtocol {
    /// Upercase first letter in string.
    func firstUppercased() -> String {
        prefix(1).uppercased() + dropFirst()
    }
}
