//
//  Shadow.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/14/21.
//

import SwiftUI

/// A structure that allows us to describe a shadow style as an object.
struct Shadow {
    let color: Color
    let radius: Double
    let x: Double
    let y: Double
}

extension View {
    func shadow(shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: CGFloat(shadow.radius),
            x: CGFloat(shadow.x),
            y: CGFloat(shadow.y)
        )
    }
}
