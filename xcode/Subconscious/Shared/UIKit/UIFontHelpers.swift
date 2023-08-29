//
//  UIFontHelpers.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/29/23.
//

import UIKit

extension UIFont {
    /// Get bold version of font
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(
            .traitBold
        ) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
    
    /// Get italic version of font
    func italic() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(
            .traitItalic
        ) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
