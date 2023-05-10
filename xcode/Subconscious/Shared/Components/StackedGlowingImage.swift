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
    
    var image: Image
    var width: CGFloat
    var height: CGFloat
    
    private var resizedImage: some View {
        image
            .resizable()
            .frame(width: width, height: height)
    }
    
    private var blendMode: BlendMode {
        colorScheme == .dark
            ? BlendMode.hardLight
            : BlendMode.darken
    }
    
    var body: some View {
        ZStack {
            resizedImage
                .blur(radius: 48)
                .blendMode(blendMode)
            
            resizedImage
                .blur(radius: 4)
                .opacity(0.5)
                .blendMode(blendMode)
            
            resizedImage
        }
    }
}
