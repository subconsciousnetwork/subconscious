//
//  Wikilinks.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/21/21.
//

import Foundation
import SwiftUI

extension String {
    static let wikilinkPattern = #"\[\[([^\]]+)\]\]"#

    /// Find ranges for wikilinks in a string
    func findWikilinks(_ text: String) -> [NSTextCheckingResult] {
        do {
            return try text.matches(pattern: String.wikilinkPattern)
        } catch {
            return []
        }
    }

    func renderingWikilinks() -> NSAttributedString {
        let string = NSMutableAttributedString(string: self)
        for result in findWikilinks(self) {
            let range = result.range(at: 1)
            string.addAttribute(.link, value: "http://google.com", range: range)
        }
        return NSAttributedString(attributedString: string)
    }
}

