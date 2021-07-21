//
//  Wikilinks.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/21/21.
//

import Foundation

extension String {
    /// Find ranges for wikilinks in a string
    func findWikilinkRanges(_ text: String) throws -> [NSTextCheckingResult] {
        try text.matches(pattern: #"\[\[([^\]]+)\]\]"#)
    }
}
