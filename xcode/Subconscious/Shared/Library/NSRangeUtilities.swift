//
//  NSRangeUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/3/22.
//

import Foundation
import UIKit

extension NSRange {
    /// Determine if an NSRange is a valid range for a given string.
    func isValidRange(for string: String) -> Bool {
        let range = Range(self, in: string)
        return range != nil
    }
}

extension NSRange {
    init(_ textRange: NSTextRange, in textContentManager: NSTextContentManager) {
        let docRange = textContentManager.documentRange
        let location = textContentManager.offset(from: docRange.location, to: textRange.location)
        let length = textContentManager.offset(from: textRange.location, to: textRange.endLocation)
        
        self.init(location: location, length: length)
    }
}
