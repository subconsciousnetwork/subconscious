//
//  Subtext2.swift
//  Subtext2
//
//  Created by Gordon Brander on 8/10/21.
//

import Foundation
extension String {
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

struct Subtext2 {
    enum Token {
        case character(Character)
        case wikilinkOpen
        case wikilinkClose
    }

    enum InlineNodeType {
        case wikilink
        case text
    }
    
    struct InlineNode {
        var type: InlineNodeType
        var text: String = ""
    }
    
    struct BlockNode {
        var children: [InlineNode] = []
    }

    static func tokenize(_ stream: inout Tape<String>) -> [Token] {
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

    static func parse(markup: String) -> BlockNode {
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
                    InlineNode(
                        type: .wikilink,
                        text: String(characters)
                    )
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
                    InlineNode(
                        type: .text,
                        text: String(characters)
                    )
                )
            }
        }
    }
}

extension Subtext2.BlockNode {
    func render(url readURL: (String) -> URL?) -> AttributedString {
        var attributedString = AttributedString()
        for child in self.children {
            switch child.type {
            case .wikilink:
                var wikilink = AttributedString(child.text)
                if let url = readURL(child.text) {
                    wikilink.link = url
                }
                attributedString.append(wikilink)
            case .text:
                let text = AttributedString(child.text)
                attributedString.append(text)
            }
        }
        return attributedString
    }
}
