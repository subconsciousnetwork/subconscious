//
//  NSRangeUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/3/22.
//

import Foundation

extension NSRange {
    /// Determine if an NSRange is a valid range for a given string.
    func isValidRange(for string: String) -> Bool {
        let range = Range(self, in: string)
        return range != nil
    }
}
