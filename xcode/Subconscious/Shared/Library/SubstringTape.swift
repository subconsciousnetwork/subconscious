//
//  SubstringTape.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/27/22.
//

import Foundation

struct SubstringTape {
    private(set) var savedIndex: Substring.Index
    private(set) var startIndex: Substring.Index
    let base: Substring

    init(_ base: Substring) {
        self.base = base
        self.startIndex = base.startIndex
        self.savedIndex = base.startIndex
    }

    func isExhausted() -> Bool {
        return self.startIndex >= self.base.endIndex
    }

    /// Save a checkpoint so you can backtrack.
    mutating func save() {
        savedIndex = startIndex
    }

    /// Backtrack to a save checkpoint.
    mutating func backtrack() {
        startIndex = savedIndex
    }

    /// Move tape index forward by one
    mutating func advance() {
        _ = self.base.formIndex(
            &self.startIndex,
            offsetBy: 1,
            limitedBy: base.endIndex
        )
    }

    mutating func consumeMatch(
        _ pattern: String
    ) -> Substring? {
        if let range = base.range(
            of: pattern,
            options: [.regularExpression, .anchored],
            range: base[startIndex...].range
        ) {
            self.startIndex = range.upperBound
            return base[range]
        }
        return nil
    }
}

struct SubtextRegexParser {
    let base: Substring

    private init(_ base: Substring) {
        self.base = base
    }

    static func parse(_ markup: String) -> [Substring] {
        var tape = SubstringTape(markup[...])
        var tokens: [Substring] = []
        if let slashlink = tape.consumeMatch(#"\/(\w|\/)+"#) {
            tokens.append(slashlink)
        }
        while !tape.isExhausted() {
            // Match slashlink preceded by space
            if let slashlink = tape.consumeMatch(#"\s\/(\w|\/)+"#) {
                tokens.append(slashlink)
            }
            // Match wikilink
            else if let wikilink = tape.consumeMatch(#"\[\[[^\]]+\]\]"#) {
                tokens.append(wikilink)
            }
            // Match bracketlink
            else if let bracketlink = tape.consumeMatch(#"<[^>]+>"#) {
                tokens.append(bracketlink)
            }
            // Match barelink
            else if let barelink = tape.consumeMatch(#"http://\S+"#) {
                tokens.append(barelink)
            }
            // Match bold
            else if let bold = tape.consumeMatch(#"\*[^\*]+\*"#) {
                tokens.append(bold)
            }
            // Match italic
            else if let italic = tape.consumeMatch(#"\_[^_]+_"#) {
                tokens.append(italic)
            }
            // Match code
            else if let code = tape.consumeMatch(#"\`[^`]+`"#) {
                tokens.append(code)
            } else {
                tape.advance()
            }
        }
        return tokens
    }
}
