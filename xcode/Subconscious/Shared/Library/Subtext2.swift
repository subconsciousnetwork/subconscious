//
//  Subtext2.swift
//  Subtext2
//
//  Created by Gordon Brander on 8/10/21.
//

import Foundation
extension String {
    /// Split lines by newline, omitting blank lines
    func splitlines() -> [String.SubSequence] {
        self.split(
            maxSplits: Int.max,
            whereSeparator: \.isNewline
        )
        .filter({ line in line != "" })
    }

    /// Safely get the character at index.
    /// This is the same as string subscribt, but it prevents panicks when the index exceeds the string
    /// boundaries.
    func characterAt(index: String.Index) -> Character? {
        if (index < self.endIndex) {
            return self[index]
        }
        return nil
    }

    /// Get character at a specific offset from startIndex
    func characterAt(offset: String.IndexDistance) -> Character? {
        let i = self.index(
            self.startIndex,
            offsetBy: offset,
            limitedBy: self.endIndex
        )
        if let i = i {
            if i < self.endIndex {
                return self[i]
            }
        }
        return nil
    }
}

extension Array {
    mutating func removeWhile(
        _ predicate: (Array.Element) -> Bool
    ) -> [Array.Element] {
        if let until = self.lastIndex(where: predicate) {
            let elements = Array(self[self.startIndex...until])
            self.removeSubrange(self.startIndex...until)
            return elements
        }
        return []
    }
}

struct Tape<T> where T: Collection {
    private(set) var position: T.Index
    var collection: T

    init(_ collection: T) {
        self.collection = collection
        self.position = collection.startIndex
    }

    /// Advance to next char and return it
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

    /// Peek forward n elements, returning an array of elements.
    func peek(count: Int) -> [T.Element] {
        let count = max(count, 0)
        var elements: [T.Element] = []
        for offset in 0...count {
            if let element = self.peek(offset) {
                elements.append(element)
            } else {
                return elements
            }
        }
        return elements
    }

    mutating func consume() -> T.Element? {
        let element = self.peek()
        self.advance()
        return element
    }
    
    mutating func consumeUntil(
        _ predicate: (T.Element) -> Bool
    ) -> [T.Element] {
        var elements: [T.Element] = []
        while true {
            let element = self.peek()
            guard element != nil else {
                break
            }
            guard predicate(element!) else {
                break
            }
            elements.append(element!)
            self.advance()
        }
        return elements
    }
    
    mutating func advance(_ offset: Int = 1) {
        if let i = collection.index(
            position,
            offsetBy: offset,
            limitedBy: collection.endIndex
        ) {
            self.position = i
        } else {
            self.position = collection.endIndex
        }
    }

    mutating func rewind() {
        self.position = self.collection.startIndex
    }
}

struct Subtext2: Hashable, Equatable {
    enum Token: Hashable, Equatable {
        case character(Character)
        case wikilinkOpen
        case wikilinkClose
    }

    enum InlineNode: Hashable, Equatable {
        case text(String)
        case wikilink(String)
        
        /// Return a plain text version (lossy)
        func renderPlain() -> String {
            switch self {
            case .wikilink(let text):
                return text
            case .text(let text):
                return text
            }
        }

        /// Return a markup string
        func renderMarkup() -> String {
            switch self {
            case .wikilink(let text):
                return "[[\(text)]]"
            case .text(let text):
                return text
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
            case .text(let text):
                return AttributedString(text)
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
            case .text(let text):
                return AttributedString(text)
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

    private static func tokenize(_ stream: inout Tape<String>) -> [Token] {
        var tokens: [Token] = []
        while true {
            let curr = stream.peek(0)
            let next = stream.peek(1)
            if curr == "[" && next == "[" {
                tokens.append(.wikilinkOpen)
                stream.advance(2)
            } else if curr == "]" && next == "]" {
                tokens.append(.wikilinkClose)
                stream.advance(2)
            } else if curr != nil {
                tokens.append(.character(curr!))
                stream.advance()
            } else {
                break
            }
        }
        return tokens
    }

    static func parse(markup: String) -> [BlockNode] {
        markup
            .splitlines()
            .map({ substring in String(substring) })
            .map(parseBlock)
    }

    private static func parseBlock(markup: String) -> BlockNode {
        var stream = Tape(markup)
        var tokens = Tape(tokenize(&stream))
        var root = BlockNode()
        while true {
            let token = tokens.consume()
            switch token {
            case .none:
                return root
            case .wikilinkOpen:
                let characters: [Character] = tokens.consumeUntil({ token in
                    switch token {
                    case .wikilinkClose:
                        return false
                    default:
                        return true
                    }
                }).compactMap({ token in
                    switch token {
                    case .character(let char):
                        return char
                    default:
                        return nil
                    }
                })
                root.children.append(
                    .wikilink(String(characters))
                )
            case .wikilinkClose:
                break
            case .character(let firstCharacter):
                var characters: [Character] = tokens.consumeUntil({ token in
                    switch token {
                    case .character:
                        return true
                    default:
                        return false
                    }
                }).compactMap({ token in
                    switch token {
                    case .character(let char):
                        return char
                    default:
                        return nil
                    }
                })
                characters.insert(firstCharacter, at: 0)
                root.children.append(
                    .text(String(characters))
                )
            }
        }
    }

    var children: [BlockNode]

    init(markup: String) {
        self.children = Self.parse(markup: markup)
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
