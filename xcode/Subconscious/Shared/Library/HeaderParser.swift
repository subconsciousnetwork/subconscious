//
//  HeaderParser.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/3/22.
//

import Foundation

/// A struct representing a single header (line)
struct Header: Hashable, Equatable {
    let name: Substring
    let value: Substring

    private init(
        name: Substring,
        value: Substring
    ) {
        self.name = name
        self.value = value
    }

    static func parse(base: Substring) -> Self {
        var tape = Tape(base)
    }
}
