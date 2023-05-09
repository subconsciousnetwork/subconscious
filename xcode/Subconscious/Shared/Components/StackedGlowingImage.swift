//
//  StackedGlowingImage.swift
//  Subconscious
//
//  Created by Ben Follington on 9/5/2023.
//

import Foundation
import SwiftUI

struct StackedGlowingImage: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ViewBuilder var image: () -> AnyView
    var width: CGFloat
    var height: CGFloat
    
    private var blendMode: BlendMode {
        colorScheme == .dark
            ? BlendMode.hardLight
            : BlendMode.darken
    }
    
    var body: some View {
        ZStack {
            let img = image()
                .frame(width: width, height: height)
            
            img
                .blur(radius: 48)
                .blendMode(blendMode)
            
            img
                .blur(radius: 4)
                .opacity(0.5)
                .blendMode(blendMode)
            
            img
        }
    }
}
