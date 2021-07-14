//
//  Truncate.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/8/21.
//

import Foundation

struct Truncate {
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
    static func getFirstPseudoSentence(_ text: String) -> String {
        let i = text.firstIndex(where: isPseudoSentenceBreak)
        if let i = i {
            return String(text.prefix(upTo: i))
        } else {
            return text
        }
    }
}
