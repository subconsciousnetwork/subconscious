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

extension StringProtocol {
    /// Truncate string to max length, appending ellipsis if truncated.
    func truncate(
        maxLength: Int = 256,
        ellipsis: String = "…"
    ) -> String {
        guard self.count > maxLength else {
            return String(self)
        }
        let adjustedMaxLength = Swift.max(0, maxLength - ellipsis.count)
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
    
    /// Take the first `maxBlocks` blocks or `Subtext.maxExcerptSize * maxBlocks` characters worth, terminating with an
    /// ellipsis. If the string is truncated, it will be sliced to the nearest word boundary to avoid breaking markup.
    /// This is used to implement `Subtext.excerpt`.
    func truncateAtWordBoundary(
        maxChars: Int
    ) -> String {
        let markup = self
        
        if markup.count <= maxChars {
            return "\(markup)"
        } else {
            // Trim the string to max length
            let index = markup.index(markup.startIndex, offsetBy: maxChars)
            var truncated = "\(markup[..<index])"
            
            // Slice the string to the nearest word boundary to avoid breaking markup.
            // This case will only ever be visible to a user when a note has a very
            // large first or second block.
            if let lastSpace = truncated.lastIndex(of: " ") {
                truncated = String(truncated[..<lastSpace])
            } else {
                return markup.truncate(maxLength: maxChars)
            }
            
            // Remove any trailing punctuation before we add the ellipsis
            // Avoids things like "Hello world.…"
            if let range = truncated.range(of: "[\\p{P}\\s]+$", options: .regularExpression) {
                truncated.removeSubrange(range)
            }
            
            return truncated + "…"
        }
    }
}

extension String {
    private static let visibleContentRegex = /[^\s]/
    
    /// Get first sentence of substring
    var firstSentence: Substring {
        self.prefix(while: { character in
            !character.isSentenceEndingPunctuation
        })
    }
    
    var hasVisibleContent: Bool {
        self.contains(Self.visibleContentRegex)
    }
    
    var fitsInUserBio: Bool {
        self.count <= UserProfileBio.maxLength
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
