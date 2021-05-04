//
//  Subtext.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/22/21.
//

import Foundation

struct Subtext: LosslessStringConvertible, Identifiable, Equatable, Hashable {
    struct Block: LosslessStringConvertible, Identifiable, Equatable, Hashable {
        /// Special characters used to denote a block type
        enum Sigil: String {
            case text = ""
            case link = "& "
            case list = "- "
            case heading = "# "
            case quote = "> "
        }

        let sigil: Sigil

        let value: String

        var description: String {
            sigil.rawValue + value
        }

        var id: Int {
            self.hashValue
        }
        
        init(sigil: Sigil, value: String) {
            self.sigil = sigil
            self.value = value
        }

        /// Init block from line of markup
        init(_ line: String) {
            if line.hasPrefix(Sigil.link.rawValue) {
                self.sigil = Sigil.link
                self.value = ltrim(prefix: Sigil.link.rawValue, value: line)
            } else if line.hasPrefix(Sigil.list.rawValue) {
                self.sigil = Sigil.list
                self.value = ltrim(prefix: Sigil.list.rawValue, value: line)
            } else if line.hasPrefix(Sigil.heading.rawValue) {
                self.sigil = Sigil.heading
                self.value = ltrim(prefix: Sigil.heading.rawValue, value: line)
            } else if line.hasPrefix(Sigil.quote.rawValue) {
                self.sigil = Sigil.quote
                self.value = ltrim(prefix: Sigil.quote.rawValue, value: line)
            } else {
                self.sigil = Sigil.text
                self.value = line
            }
        }
    }

    let blocks: [Block]

    var id: Int {
        self.hashValue
    }
    
    /// Get Subtext as markup string
    var description: String {
        blocks.map({ block in block.description }).joined(separator: "\n\n")
    }

    // Get contents of first text block
    var firstText: String {
        for block in blocks {
            if block.sigil == Block.Sigil.text {
                return block.value
            }
        }
        return ""
    }

    init(blocks: [Block]) {
        self.blocks = blocks
    }

    
    init(_ markup: String) {
        self.init(
            blocks: markup
                // Note that split omits empty subsequences by default.
                // This means we do not have to filter out blank lines caused
                // by multiple concurrent line breaks, since split omits them.
                .split(whereSeparator: \.isNewline)
                .map({ sub in Block(String(sub)) })
        )
    }
}
