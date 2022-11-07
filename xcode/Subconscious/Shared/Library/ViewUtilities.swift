//
//  ViewUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/16/22.
//

import SwiftUI

struct IndependentlyRoundedRectangle: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path: UIBezierPath = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    /// Corner radius modifier that allows us to set specific corners to round
    func cornerRadius(
        _ radius: CGFloat,
        corners: UIRectCorner
    ) -> some View {
        self.clipShape(
            IndependentlyRoundedRectangle(
                radius: radius,
                corners: corners
            )
        )
    }
}
