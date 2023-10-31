//
//  UITextViewHelpers.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import Foundation
import UIKit

extension UITextView {
    func textRange(nsRange: NSRange) -> UITextRange? {
        guard
            let rangeStart = position(
                from: beginningOfDocument,
                offset: nsRange.location
            ),
            let rangeEnd = position(
                from: rangeStart,
                offset: nsRange.length
            )
        else {
            return nil
        }
        return textRange(from: rangeStart, to: rangeEnd)
    }
    
    func text(in range: NSRange) -> String? {
        guard let textRange = textRange(nsRange: range) else {
            return nil
        }
        return text(in: textRange)
    }
    
    /// Shortcut for setting `isUserInteractionEnabled` and `isEditable`
    /// together.
    func setModifiable(_ isModifiable: Bool) {
        if (self.isUserInteractionEnabled != isModifiable) {
            self.isUserInteractionEnabled = isModifiable
        }
        if (self.isEditable != isModifiable) {
            self.isEditable = isModifiable
        }
    }
}
