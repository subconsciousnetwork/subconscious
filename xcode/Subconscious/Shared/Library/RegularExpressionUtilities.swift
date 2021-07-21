//
//  RegularExpressionUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/21/21.
//

import Foundation

extension String {
    func matches(
        pattern: String,
        options: NSRegularExpression.MatchingOptions = []
    ) throws -> [NSTextCheckingResult] {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try NSRegularExpression(pattern: pattern)
        return regex.matches(in: self, options: options, range: range)
    }
}
