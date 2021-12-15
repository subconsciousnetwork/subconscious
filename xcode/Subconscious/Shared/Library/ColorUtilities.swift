//
//  ColorUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

extension Color {
    static func chooseForState(
        isPressed: Bool,
        isEnabled: Bool,
        normal: Color,
        pressed: Color,
        disabled: Color
    ) -> Color {
        if !isEnabled {
            return disabled
        } else {
            if isPressed {
                return pressed
            } else {
                return normal
            }
        }
    }
}
