//
//  FirstRunOrbitEffectView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 1/7/2023.
//

import Foundation
import SwiftUI

struct RotatingRingView<Content: View>: View {
    var radius: CGFloat = 150
    var speed: CGFloat = 1
    let content: [Content]
    @State private var isAnimating = false

    var body: some View {
        Group {
            ForEach(0..<content.count, id: \.self) { index in
                content[index]
                    // distribute around circle
                    .rotationEffect(Angle(degrees: Double(index) / Double(content.count) * 360))
                    // rotate each individual item to counteract overall orbit rotation
                    // this keeps the orbs oriented correctly
                    .rotationEffect(Angle(degrees: isAnimating ? 0 : 360))
                    .offset(y: -radius)
                    // unrotate, preserving translation from .offset
                    .rotationEffect(Angle(degrees: -Double(index) / Double(content.count) * 360))
            }
        }
        // rotate the overall ring, causing it to orbit
        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
        .animation(
            .linear(duration: 10/speed)
                .repeatForever(autoreverses: false),
            value: self.isAnimating
        )
        .task {
            // must use .task to begin animation instead of .onAppear
            // otherwise the animation uses incorrect layout dimensions
            self.isAnimating = true
        }
    }
}



struct FirstRunOrbitEffectView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var shadow: Color {
        Color.brandDropShadow(colorScheme).opacity(0.25)
    }
    
    var innerRing: [GenerativeProfilePic] {
        [Int](
            repeating: 0,
            count: 8
        ).map { _ in
            GenerativeProfilePic(did: Did.dummyData(), size: 32)
        }
    }
    
    var outerRing: [GenerativeProfilePic] {
        [Int](
            repeating: 0,
            count: 15
        ).map { _ in
            GenerativeProfilePic(did: Did.dummyData(), size: 20)
        }
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            StackedGlowingImage() {
                Image("sub_logo").resizable()
            }
            .aspectRatio(contentMode: .fit)
            .frame(
                width: 80,
                height: 80
            )
                
            RotatingRingView(
                radius: 64,
                speed: 0.3,
                content: innerRing
            )
            .opacity(0.75)
            .shadow(color: shadow, radius: 4, x:0, y: 5)
                
            RotatingRingView(
                radius: 100,
                speed: 0.15,
                content: outerRing
            )
            .opacity(0.4)
            .shadow(color: shadow, radius: 4, x:0, y: 5)
        }
        .frame(width: 244, height: 244)
    }
}

struct FirstRunOrbitEffectView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunOrbitEffectView()
    }
}
