//
//  StackedGlowingImage.swift
//  Subconscious
//
//  Created by Ben Follington on 9/5/2023.
//

import Foundation
import SwiftUI

struct StackedGlowingImage<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    var width: CGFloat
    var height: CGFloat
    @ViewBuilder var content: () -> Content
    
    private var blendMode: BlendMode {
        colorScheme == .dark
            ? BlendMode.hardLight
            : BlendMode.darken
    }
    
    private var img: some View {
        content()
            .frame(width: width, height: height)
    }
    
    var body: some View {
        ZStack {
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
