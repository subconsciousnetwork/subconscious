//
//  StringSplitAtRange.swift
//  Subconscious
//
//  Created by Gordon Brander on 7/31/23.
//

import Foundation

extension String {
    /// Split a string at a given range.
    ///
    /// The text inside the range is discarded. The text to either end of the
    /// range is returned.
    ///
    /// This is is similar to the behavior of a text editor when you select
    /// text and hit enter.
    func splitAtRange(_ range: Range<String.Index>) -> (String, String) {
        let range = range.relative(to: self)
        let a = String(self[..<range.lowerBound])
        let b = String(self[range.upperBound...])
        return (a, b)
    }
    
    /// Split a string at a given NSRange.
    func splitAtRange(_ nsRange: NSRange) -> (String, String)? {
        guard let range = Range(nsRange, in: self) else {
            return nil
        }
        return self.splitAtRange(range)
    }
}
