//
//  WikilinkText.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/15/22.
//

import Foundation

/// Helper struct for representing a string that is wikilink text
struct WikilinkMarkup: Hashable, Equatable, CustomStringConvertible {
    var markup: String

    var text: Substring {
        markup.dropFirst(2).dropLast(2)
    }

    var description: String {
        markup
    }

    /// Get text from opening brackets through to end of wikilink text,
    /// but excluding closing brackets.
    var withoutClosingTag: Substring {
        description.dropLast(2)
    }

    init(text: String) {
        self.markup = "[[\(text)]]"
    }
}
