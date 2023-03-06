//
//  Prose.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/2/23.
//

import Foundation

enum Prose {}

extension Prose {
    static func chooseTitle(
        address: MemoAddress?,
        title: String?
    ) -> String? {
        if let title = title {
            return title
        }
        if let address = address {
            return address.slug.toTitle()
        }
        return nil
    }
    
    static func chooseTitle(
        address: MemoAddress?,
        title: String?,
        fallback: String
    ) -> String {
        chooseTitle(address: address, title: title) ?? fallback
    }
}

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
    func truncate(maxLength: Int = 140, ellipsis: String = "…") -> String {
        guard self.count > maxLength else {
            return self
        }
        let truncated = self.prefix(
            maxLength
        ).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return "\(truncated)\(ellipsis)"
    }

    /// Get first sentence of substring
    var firstSentence: Substring {
        self.prefix(while: { character in
            !character.isSentenceEndingPunctuation
        })
    }

    /// Derive title from string.
    /// Returns the first sentence-like structure.
    /// - Parameter fallback: The fallback string to use if derived title is empty.
    /// - Parameter maxLength: The max length of derived title. 140 characters by default.
    /// - Returns:
    func title(
        fallback: String = "",
        maxLength: Int = 140
    ) -> String {
        let title = String(self.firstSentence).truncate()
        return title.isEmpty ? fallback : title
    }
}
