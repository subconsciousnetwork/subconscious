//
//  Markup.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/15/22.
//

import Foundation

protocol TaggedMarkup: LosslessStringConvertible {
    var text: Substring { get }
    var markupWithoutClosingTag: Substring { get }
    init(text: String)
}

/// Text markup helpers
enum Markup {}

extension Markup {
    private static func isTag(
        _ string: String,
        opening: String,
        closing: String
    ) -> Bool {
        string.hasPrefix(opening) && string.hasSuffix(closing)
    }

    /// A wikilink string
    struct Wikilink: Hashable, Equatable, TaggedMarkup {
        var markup: String

        var text: Substring {
            markup.dropFirst(2).dropLast(2)
        }

        var description: String {
            markup
        }

        /// Get text from opening brackets through to end of wikilink text,
        /// but excluding closing brackets.
        var markupWithoutClosingTag: Substring {
            markup.dropLast(2)
        }

        init?(_ description: String) {
            guard isTag(description, opening: "[[", closing: "]]") else {
                return nil
            }
            self.markup = description
        }

        init(text: String) {
            self.markup = "[[\(text)]]"
        }
    }

    /// A bold string
    struct Bold: Hashable, Equatable, TaggedMarkup {
        var markup: String

        var text: Substring {
            markup.dropFirst(1).dropLast(1)
        }

        var description: String {
            markup
        }

        /// Get text from opening brackets through to end of wikilink text,
        /// but excluding closing brackets.
        var markupWithoutClosingTag: Substring {
            markup.dropLast(1)
        }

        init?(_ description: String) {
            guard isTag(description, opening: "*", closing: "*") else {
                return nil
            }
            self.markup = description
        }

        init(text: String) {
            self.markup = "*\(text)*"
        }
    }

    /// An italic string
    struct Italic: Hashable, Equatable, TaggedMarkup {
        var markup: String

        var text: Substring {
            markup.dropFirst(1).dropLast(1)
        }

        var description: String {
            markup
        }

        /// Get text from opening brackets through to end of wikilink text,
        /// but excluding closing brackets.
        var markupWithoutClosingTag: Substring {
            markup.dropLast(1)
        }

        init?(_ description: String) {
            guard isTag(description, opening: "_", closing: "_") else {
                return nil
            }
            self.markup = description
        }

        init(text: String) {
            self.markup = "_\(text)_"
        }
    }
}
