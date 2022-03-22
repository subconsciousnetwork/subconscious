//
//  Shadow.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/22/22.
//

import SwiftUI

// Describe s
struct ShadowStyle {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
}

extension ShadowStyle {
    static let lv1 = ShadowStyle(
        color: .black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
    )
}

extension View {
    /// Synonym for `shadow` that takes a `ShadowStyle` struct
    func shadow(style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}
