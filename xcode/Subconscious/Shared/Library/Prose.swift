//
//  Prose.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/2/23.
//

import Foundation

extension Character {
    private static let sentenceEndingPunctuation: Set<Character> = Set(
        [
            ".",
            "!",
            "?",
            "\n"
        ]
    )
    
    var isSentenceEndingPunctuation: Bool {
        Self.sentenceEndingPunctuation.contains(self)
    }
}

extension String {
    /// Truncate string to max length, appending ellipsis if truncated.
    func truncate(
        maxLength: Int = 256,
        ellipsis: String = "…"
    ) -> String {
        guard self.count > maxLength else {
            return self
        }
        let adjustedMaxLength = max(0, maxLength - ellipsis.count)
        guard adjustedMaxLength > 0 else {
            return ""
        }
        let truncated = self.prefix(
            adjustedMaxLength
        ).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return !truncated.isEmpty ? "\(truncated)\(ellipsis)" : ""
    }

    /// Get first sentence of substring
    var firstSentence: Substring {
        self.prefix(while: { character in
            !character.isSentenceEndingPunctuation
        })
    }

    /// Derive title from string.
    /// Returns the first sentence-like structure, truncated to `maxLength`.
    /// - Parameter fallback: The fallback string to use if derived title is empty.
    /// - Parameter maxLength: The max length of derived title. 140 characters by default.
    /// - Returns:
    func title(
        maxLength: Int = 140,
        ellipsis: String = "…",
        fallback: String = String(localized: "Untitled")
    ) -> String {
        let firstSentence = self.firstSentence
        guard !firstSentence.isEmpty else {
            return fallback
        }
        return String(firstSentence).truncate(
            maxLength: maxLength,
            ellipsis: ellipsis
        )
    }
}
