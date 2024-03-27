//
//  ShadowStyle.swift
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
    
    static let transclude = ShadowStyle(
        color: DeckTheme.cardShadow.opacity(0.08),
        radius: 1.5,
        x: 0,
        y: 1.5
    )
    
    static let editorSheet = ShadowStyle(
        color: DeckTheme.cardShadow.opacity(0.05),
        radius: 2,
        x: 0,
        y: -0.5
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
