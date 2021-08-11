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
    func matchWikilinks() -> [NSTextCheckingResult] {
        do {
            return try self.matches(pattern: String.wikilinkPattern)
        } catch {
            return []
        }
    }

    /// Get an array of Strings, each of which is the text portion of a Wikilink
    func extractWikilinks() -> [String] {
        self.matchWikilinks().compactMap({ result in
            let nsrange = result.range(at: 1)
            if let range = Range(nsrange, in: self) {
                return String(self[range])
            }
            return nil
        })
    }
}
