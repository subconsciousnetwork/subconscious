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


// https://gist.github.com/krzyzanowskim/057676af670f06fa6061473ac28a6c58
extension NSRange {

    static let notFound = NSRange(location: NSNotFound, length: 0)

    var isEmpty: Bool {
        length == 0
    }

    init(_ textRange: NSTextRange, in textContentManager: NSTextContentManager) {
        let offset = textContentManager.offset(from: textContentManager.documentRange.location, to: textRange.location)
        let length = textContentManager.offset(from: textRange.location, to: textRange.endLocation)
        self.init(location: offset, length: length)
    }

    init(_ textLocation: NSTextLocation, in textContentManager: NSTextContentManager) {
        let offset = textContentManager.offset(from: textContentManager.documentRange.location, to: textLocation)
        self.init(location: offset, length: 0)
    }

}
