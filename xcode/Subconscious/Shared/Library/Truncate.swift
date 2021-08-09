//
//  Truncate.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/8/21.
//

import Foundation

extension String {
    /// Determine if a character is a pseudo-sentence break character.
    static func isPseudoSentenceBreak(_ character: Character) -> Bool {
        return (
            character.isNewline ||
            character == "." ||
            character == "!" ||
            character == "?" ||
            character == ";"
        )
    }

    /// Extracts the first "pseudo-sentence" from some text.
    /// We use newlines, periods, and semicolons to denote a pseudosentence break.
    var firstPseudoSentence: String {
        let text = self
        let i = text.firstIndex(where: Self.isPseudoSentenceBreak)
        if let i = i {
            return String(text.prefix(upTo: i))
        } else {
            return text
        }
    }

    /// Truncates by word, up to a given number of characters.
    func truncatingByWord(characters limit: Int) -> String {
        if self.count <= limit {
            return self
        } else {
            return self.prefix(limit)
                .split(separator: " ")
                .dropLast()
                .joined(separator: " ")
        }
    }

    /// Remove quotation marks from string
    func unquote() -> String {
        self.replacingOccurrences(
            of: #"["']"#,
            with: "",
            options: .regularExpression
        )
    }

    /// Derive a title from free-range text by taking the first sentence and cleaning it up.
    func derivingTitle() -> String {
        self
            .firstPseudoSentence
            /// Remove quotes. We rarely want these in derived titles
            .unquote()
            /// Truncate, so it doesn't get too long
            .truncatingByWord(characters: 120)
    }
}
