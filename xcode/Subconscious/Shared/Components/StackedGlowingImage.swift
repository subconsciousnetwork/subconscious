//
//  StackedGlowingImage.swift
//  Subconscious
//
//  Created by Ben Follington on 9/5/2023.
//

import Foundation
import SwiftUI

struct StackedGlowingImage: View {
    var image: Image
    var width: CGFloat
    var height: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    private var shadow: Color {
        switch colorScheme {
        case .dark:
            return .brandBgBlack
        default:
            return .brandMarkPurple
        }
    }
    
    var body: some View {
        ZStack {
            let img = image
                .resizable()
                .frame(width: width, height: height)
            
            img
                .blur(radius: 48)
                .opacity(1)
                .blendMode(colorScheme == .dark ? .hardLight : .darken)
            
            img
                .blur(radius: 8)
                .opacity(0.2)
                .blendMode(colorScheme == .dark ? .darken : .plusLighter)
            
            img
        }
    }
}
