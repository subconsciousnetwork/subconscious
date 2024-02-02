//
//  TruncateWithGradientViewModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 8/1/2024.
//

import SwiftUI

/// Truncate a view at a max height with a gradient overlay
struct TruncateWithGradientViewModifier: ViewModifier {
    var maxHeight: CGFloat
    
    private static let maxGradientHeight: CGFloat = 80
    
    func body(content: Content) -> some View {
        content
            .frame(maxHeight: maxHeight, alignment: .topLeading)
            .clipped()
            .mask(
                GeometryReader { geo in
                    if (geo.size.height >= maxHeight) {
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    .black,
                                    .black,
                                    .clear
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Rectangle().fill(.black)
                    }
                }
            )
    }
}

extension View {
    /// Truncate a view at a max height with a gradient overlay
    func truncateWithGradient(maxHeight: CGFloat) -> some View {
        self.modifier(TruncateWithGradientViewModifier(maxHeight: maxHeight))
    }
}


struct TruncateWithGradientViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
                .truncateWithGradient(maxHeight: 64)
                .background(.yellow)
        }
    }
}
