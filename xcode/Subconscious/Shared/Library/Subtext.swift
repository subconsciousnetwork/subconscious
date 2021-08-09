//
//  Subtext.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/22/21.
//

import Foundation

public struct Subtext:
    CustomStringConvertible, Identifiable, Equatable, Hashable {
    public struct BlankBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        public var description: String { "" }
        public let id = UUID()
    }

    public struct TextBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        public var description: String { self.value }
        public let id = UUID()
        public let value: String
    }

    public struct LinkBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        static let sigil = "&"
        public var description: String { "& " + self.value }
        public let id = UUID()
        public let value: String
    }

    public struct ListBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        public static let sigil = "-"
        public var description: String { "- " + self.value }
        public let id = UUID()
        public let value: String
    }

    public struct HeadingBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        public static let sigil = "#"
        public var description: String { "# " + self.value }
        public let id = UUID()
        public let value: String
    }

    public struct QuoteBlock:
        CustomStringConvertible, Identifiable, Equatable, Hashable {
        public static let sigil = ">"
        public var description: String { "> " + self.value }
        public let id = UUID()
        public let value: String
    }

    public enum Block: CustomStringConvertible, Identifiable, Equatable, Hashable {
        case blank(BlankBlock)
        case text(TextBlock)
        case link(LinkBlock)
        case list(ListBlock)
        case heading(HeadingBlock)
        case quote(QuoteBlock)

        public var id: UUID {
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

        public var markup: String {
            description
        }

        public var description: String {
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

        public var value: String {
            switch self {
            case .text(let block):
                return block.value
            case .heading(let block):
                return block.value
            case .quote(let block):
                return block.value
            case .list(let block):
                return block.value
            default:
                return ""
            }
        }
        
        private static func trimSigil(
            from value: String,
            sigil: String
        ) -> String {
            value.replacingOccurrences(
                of: #"^\#(sigil)\s+"#,
                with: "",
                options: .regularExpression,
                range: nil
            )
        }

        /// Determine if block is a content block
        public static func isContent(_ block: Block) -> Bool {
            switch block {
            case .text:
                return true
            case .heading:
                return true
            case .quote:
                return true
            case .list:
                return true
            default:
                return false
            }
        }
        
        public static func fromLine(_ line: String) -> Block {
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

    public static func excerpt(markup: String) -> String {
        Subtext(markup: markup).excerpt
    }

    /// Render blocks as plain text (lossy)
    public static func strip(_ blocks: [Block]) -> String {
        blocks
            .map({ block in block.value })
            .joined(separator: "\n")
    }

    public var blocks: [Block]

    public var id: Int {
        self.hashValue
    }

    public var excerpt: String {
        blocks
            .first(where: Block.isContent)
            .map({ block in block.value }) ?? ""
    }

    public var markup: String {
        blocks
            .map({ block in block.description })
            .joined(separator: "\n")
    }

    public var description: String {
        markup
    }

    public var text: String {
        Self.strip(self.blocks)
    }

    public init(blocks: [Block]) {
        self.blocks = blocks
    }

    public init(markup: String) {
        self.blocks = markup.split(
            maxSplits: Int.max,
            omittingEmptySubsequences: false,
            whereSeparator: \.isNewline
        )
        .map({ sub in Block.fromLine(String(sub)) })
    }

    public func prefix(_ max: Int) -> Subtext {
        Subtext(blocks: Array(self.blocks.prefix(max)))
    }

    public func filter(_ predicate: (Block) -> Bool) -> Subtext {
        Subtext(blocks: self.blocks.filter(predicate))
    }
}
