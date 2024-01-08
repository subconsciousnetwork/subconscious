//
//  TruncateWithGradientViewModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 8/1/2024.
//

import SwiftUI

/// Truncate a view at a max height with a gradient overlay
struct TruncateWithGradientViewModifier: ViewModifier {
    var color: Color
    var maxHeight: CGFloat
    
    private static let maxGradientHeight: CGFloat = 80
    
    func body(content: Content) -> some View {
        content
            .frame(maxHeight: maxHeight, alignment: .topLeading)
            .clipped()
            .overlay(
                GeometryReader {
                    geo in
                    if (geo.size.height >= maxHeight) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(
                                        stops: [
                                            Gradient.Stop(
                                                color: color.opacity(0),
                                                location: 0.1
                                            ),
                                            Gradient.Stop(
                                                color: color,
                                                location: 0.9
                                            )
                                        ]
                                    ),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                height: min(
                                    maxHeight / 2,
                                    Self.maxGradientHeight
                                ),
                                alignment: .bottom
                            )
                            .offset(
                                y: geo.size.height - min(
                                    maxHeight / 2,
                                    Self.maxGradientHeight
                                )
                            )
                            .allowsHitTesting(false)
                    }
                },
                alignment: .bottom
            )
    }
}

extension View {
    /// Modify a view so that it expands to fill the whole available
    /// horizontal space, with content aligned leading.
    func truncateWithGradient(color: Color, maxHeight: CGFloat) -> some View {
        self.modifier(TruncateWithGradientViewModifier(color: color, maxHeight: maxHeight))
    }
}


struct TruncateWithGradientViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
                .truncateWithGradient(color: .red, maxHeight: 64)
                .background(.yellow)
        }
    }
}
