//
//  Subtext2.swift
//  Subtext2
//
//  Created by Gordon Brander on 8/10/21.
//
import Foundation

struct Tape<T>
where T: Collection,
      T.Element: Equatable,
      T.SubSequence: Equatable
{
    private(set) var position: T.Index
    let collection: T

    init(_ collection: T) {
        self.collection = collection
        self.position = collection.startIndex
    }

    func isExhausted() -> Bool {
        self.position >= self.collection.endIndex
    }

    /// Peek forward one element
    func peek(_ offset: Int = 0) -> T.Element? {
        if let i = collection.index(
            position,
            offsetBy: offset,
            limitedBy: collection.endIndex
        ) {
            if i < collection.endIndex {
                return collection[i]
            }
        }
        return nil
    }

    /// Peek forward by `offset`, returning a subsequence from `position` through `offset`,
    /// or from `position` through `endIndex`, whichever is smaller..
    func peek(count: Int) -> T.SubSequence {
        if let i = collection.index(
            position,
            offsetBy: count,
            limitedBy: collection.endIndex
        ) {
            if position < collection.endIndex && i <= collection.endIndex {
                return collection[position..<i]
            }
        }
        return collection[position..<collection.endIndex]
    }

    /// Consume one element, returning it, and advancing tape by 1
    @discardableResult mutating func consume() -> T.Element? {
        if position < collection.endIndex {
            let element = collection[position]
            self.advance()
            return element
        }
        return nil
    }

    mutating func consumeMatch(_ element: T.Element) -> Bool {
        let next = self.peek()
        if next == element {
            self.advance()
            return true
        }
        return false
    }

    mutating func consumeMatch(subsequence: T.SubSequence) -> Bool {
        let next = self.peek(count: subsequence.count)
        if next == subsequence {
            self.advance(subsequence.count)
            return true
        }
        return false
    }

    @discardableResult mutating func advance(
        _ offset: Int = 1
    ) -> Bool {
        self.collection.formIndex(
            &self.position,
            offsetBy: offset,
            limitedBy: collection.endIndex
        )
    }
}

struct Subtext2: Hashable, Equatable {
    enum Token: Hashable, Equatable {
        case character(Character)
        case blockbreak
        case linebreak
        case wikilinkOpen
        case wikilinkClose
        case url(String)
    }

    enum InlineNode: Hashable, Equatable {
        case text(String)
        case wikilink(String)
        case url(String)
        case linebreak
        
        /// Return a plain text version (lossy)
        func renderPlain() -> String {
            switch self {
            case .wikilink(let text):
                return text
            case .url(let href):
                return href
            case .text(let text):
                return text
            case .linebreak:
                return "\n"
            }
        }

        /// Return a markup string
        func renderMarkup() -> String {
            switch self {
            case .wikilink(let text):
                return "[[\(text)]]"
            case .url(let href):
                return href
            case .text(let text):
                return text
            case .linebreak:
                return "\n"
            }
        }

        /// Render as attributed string.
        func renderAttributedString(
            url: (String) -> URL?
        ) -> AttributedString {
            switch self {
            case .wikilink(let text):
                var link = AttributedString(text)
                if let url = url(text) {
                    link.link = url
                }
                return link
            case .url(let href):
                var link = AttributedString(href)
                link.link = URL(string: href)
                return link
            case .text(let text):
                return AttributedString(text)
            case .linebreak:
                return AttributedString("\n")
            }
        }

        /// Return a markup string, attributed to highlight syntax
        func renderMarkupAttributedString(
            url: (String) -> URL?
        ) -> AttributedString {
            switch self {
            case .wikilink(let text):
                let secondary = Constants.Text.secondary
                var attributedString = AttributedString()
                let open = AttributedString(
                    "[[",
                    attributes: secondary
                )
                let close = AttributedString(
                    "]]",
                    attributes: secondary
                )
                var link = AttributedString(text)
                if let url = url(text) {
                    link.link = url
                }
                attributedString.append(open)
                attributedString.append(link)
                attributedString.append(close)
                return attributedString
            case .url(let href):
                var link = AttributedString(href)
                link.link = URL(string: href)
                return link
            case .text(let text):
                return AttributedString(text)
            case .linebreak:
                return AttributedString("\n")
            }
        }
    }

    struct BlockNode: Hashable, Equatable, Identifiable {
        var id = UUID()
        var children: [InlineNode] = []

        /// Pluck text of wikilinks out of block, returning a list of strings
        func wikilinks() -> [String] {
            children.compactMap({ token in
                switch token {
                case .wikilink(let text):
                    return text
                default:
                    return nil
                }
            })
        }

        func renderPlain() -> String {
            children.map({ inline in
                inline.renderPlain()
            }).joined()
        }

        func renderMarkup() -> String {
            children.map({ inline in
                inline.renderMarkup()
            }).joined()
        }
        
        func renderAttributedString(
            url: (String) -> URL?
        ) -> AttributedString {
            var attributedString = AttributedString()
            for child in children {
                attributedString.append(child.renderAttributedString(url: url))
            }
            return attributedString
        }

        func renderMarkupAttributedString(
            url: (String) -> URL?
        ) -> AttributedString {
            var attributedString = AttributedString()
            for child in children {
                attributedString.append(
                    child.renderMarkupAttributedString(url: url)
                )
            }
            return attributedString
        }
    }

    private static func tokenize(_ markup: String) -> [Token] {
        var stream = Tape(markup)
        var tokens: [Token] = []
        while !stream.isExhausted() {
            let curr = stream.consume()!
            if curr == "[" && stream.consumeMatch("[") {
                tokens.append(.wikilinkOpen)
            } else if curr == "]" && stream.consumeMatch("]") {
                tokens.append(.wikilinkClose)
            } else if curr == "\n" && stream.consumeMatch("\n") {
                tokens.append(.blockbreak)
            } else if curr == "\n" {
                tokens.append(.linebreak)
            } else if
                curr == "h" &&
                stream.consumeMatch(subsequence: "ttp://")
            {
                let urlBody = parseNonWhitespace(&stream)
                tokens.append(.url(String("http://" + urlBody)))
            } else if
                curr == "h" &&
                stream.consumeMatch(subsequence: "ttps://")
            {
                let urlBody = parseNonWhitespace(&stream)
                tokens.append(.url(String("https://" + urlBody)))
            } else {
                tokens.append(.character(curr))
            }
        }
        return tokens
    }

    private static func parseRoot(
        _ tokens: inout Tape<[Token]>
    ) -> [BlockNode] {
        var node: [BlockNode] = []
        while !tokens.isExhausted() {
            let block = parseBlock(&tokens)
            node.append(block)
        }
        return node
    }

    private static func parseBlock(
        _ tokens: inout Tape<[Token]>
    ) -> BlockNode {
        var node = BlockNode()
        while !tokens.isExhausted() {
            let token = tokens.consume()!
            switch token {
            case .wikilinkOpen:
                let wikilink = parseWikilink(&tokens)
                node.children.append(wikilink)
            case .character(let char):
                var text = parseText(&tokens)
                text.insert(char, at: text.startIndex)
                node.children.append(.text(text))
            // Catch stray wikilink closes that don't have a corresponding
            // wikilink open. Treat them as plain text.
            case .wikilinkClose:
                node.children.append(.text("]]"))
            case .linebreak:
                node.children.append(.linebreak)
            case .url(let url):
                node.children.append(.url(url))
            case .blockbreak:
                return node
            }
        }
        return node
    }

    private static func parseWikilink(
        _ tokens: inout Tape<[Token]>
    ) -> InlineNode {
        // Wikilink open tag is already consumed by this point.
        // Consume text portion of wikilink.
        let text = parseText(&tokens)
        // If we find a closing tag, create a wikilink
        if tokens.consumeMatch(.wikilinkClose) {
            return .wikilink(text)
        // Otherwise, return plain text
        } else {
            return .text("[[" + text)
        }
    }

    private static func parseText(
        _ tokens: inout Tape<[Token]>
    ) -> String {
        var characters: [Character] = []
        loop: while !tokens.isExhausted() {
            let char = tokens.peek()!
            switch char {
            case .character(let char):
                characters.append(char)
            default:
                break loop
            }
            tokens.advance()
        }
        return String(characters)
    }

    private static func parseNonWhitespace(
        _ tokens: inout Tape<String>
    ) -> String {
        var characters: [Character] = []
        loop: while !tokens.isExhausted() {
            let char = tokens.peek()!
            if !char.isWhitespace {
                characters.append(char)
            } else {
                break loop
            }
            tokens.advance()
        }
        return String(characters)
    }
    
    var children: [BlockNode]

    init(markup: String) {
        var tokens = Tape(Self.tokenize(markup))
        self.children = Self.parseRoot(&tokens)
    }

    /// Get a short plain text string version of this Subtext.
    func excerpt() -> String {
        children.first?.renderPlain() ?? ""
    }

    /// Get all wikilinks that appear in this Subtext.
    func wikilinks(markup: String) -> [String] {
        children.flatMap({ block in
            block.wikilinks()
        })
    }

    func renderPlain() -> String {
        children
            .map({ block in block.renderPlain() })
            .joined(separator: "\n\n")
    }

    func renderMarkup() -> String {
        children
            .map({ block in block.renderMarkup() })
            .joined(separator: "\n\n")
    }

    func renderAttributedString(url: (String) -> URL?) -> AttributedString {
        var attributedString = AttributedString()
        let br = AttributedString("\n\n")
        for child in children {
            attributedString.append(child.renderAttributedString(url: url))
            attributedString.append(br)
        }
        return attributedString
    }

    func renderMarkupAttributedString(
        url: (String) -> URL?
    ) -> AttributedString {
        var attributedString = AttributedString()
        let br = AttributedString("\n\n")
        for child in children {
            attributedString.append(
                child.renderMarkupAttributedString(url: url)
            )
            attributedString.append(br)
        }
        return attributedString
    }
}
