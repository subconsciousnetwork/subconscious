//
//  Subtext.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/22/21.
//

import Foundation

struct Subtext: CustomStringConvertible, Identifiable, Equatable, Hashable {
    struct BlankBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        let id = UUID()
        var description: String { "" }
    }

    struct TextBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        let id = UUID()
        var description: String { self.value }
        let value: String
    }
    
    struct LinkBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        static let sigil = "&"
        let id = UUID()
        var description: String { "& " + self.value }
        let value: String
    }

    struct ListBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        static let sigil = "-"
        let id = UUID()
        var description: String { "- " + self.value }
        let value: String
    }

    struct HeadingBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        static let sigil = "#"
        let id = UUID()
        var description: String { "# " + self.value }
        let value: String
    }

    struct QuoteBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        static let sigil = ">"
        let id = UUID()
        var description: String { "> " + self.value }
        let value: String
    }
    
    enum Block: CustomStringConvertible, Identifiable, Equatable, Hashable {
        case blank(BlankBlock)
        case text(TextBlock)
        case link(LinkBlock)
        case list(ListBlock)
        case heading(HeadingBlock)
        case quote(QuoteBlock)

        var id: UUID {
            switch self {
            case .blank(let block):
                return block.id
            case .text(let block):
                return block.id
            case .link(let block):
                return block.id
            case .list(let block):
                return block.id
            case .heading(let block):
                return block.id
            case .quote(let block):
                return block.id
            }
        }

        var description: String {
            switch self {
            case .blank(let block):
                return block.description
            case .text(let block):
                return block.description
            case .link(let block):
                return block.description
            case .list(let block):
                return block.description
            case .heading(let block):
                return block.description
            case .quote(let block):
                return block.description
            }
        }

        private static func trimSigil(from value: String, sigil: String) -> String {
            StringUtilities.ltrim(prefix: LinkBlock.sigil + " ", value: value)
        }
        
        static func fromLine(_ line: String) -> Block {
            if line.hasPrefix(LinkBlock.sigil) {
                return Block.link(
                    .init(
                        value: trimSigil(
                            from: line,
                            sigil: LinkBlock.sigil
                        )
                    )
                )
            } else if line.hasPrefix(ListBlock.sigil) {
                return Block.list(
                    .init(
                        value: trimSigil(
                            from: line,
                            sigil: ListBlock.sigil
                        )
                    )
                )
            } else if line.hasPrefix(HeadingBlock.sigil) {
                return Block.heading(
                    .init(
                        value: trimSigil(
                            from: line,
                            sigil: HeadingBlock.sigil
                        )
                    )
                )
            } else if line.hasPrefix(QuoteBlock.sigil) {
                return Block.quote(
                    .init(
                        value: trimSigil(
                            from: line,
                            sigil: QuoteBlock.sigil
                        )
                    )
                )
            } else if line.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                return Block.blank(BlankBlock())
            } else {
                return Block.text(TextBlock(value: line))
            }
        }
    }
    
    let blocks: [Block]

    var id: Int {
        self.hashValue
    }

    var description: String {
        blocks.map({ block in block.description }).joined(separator: "\n")
    }
        
    init(blocks: [Block]) {
        self.blocks = blocks
    }

    init(_ markup: String) {
        self.init(
            blocks: markup
                .split(
                    maxSplits: Int.max,
                    omittingEmptySubsequences: false,
                    whereSeparator: \.isNewline
                )
                .map({ sub in Block.fromLine(String(sub)) })
        )
    }
}
