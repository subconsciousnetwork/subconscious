//
//  MetalTest.swift
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
                    .rotationEffect(Angle(degrees: Double(index) / Double(content.count) * 360))
                    .rotationEffect(Angle(degrees: isAnimating ? 0 : 360))
                    .offset(y: -radius) // Adjust this value based on your needs.
                    .rotationEffect(Angle(degrees: -Double(index) / Double(content.count) * 360))
            }
        }
        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
        .animation(Animation.linear(duration: 10/speed).repeatForever(autoreverses: false), value: self.isAnimating)
        .task {
            self.isAnimating = true
        }
    }
}



struct FirstRunOrbitEffectView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .center) {
            StackedGlowingImage() {
                Image("sub_logo").resizable()
            }
            .aspectRatio(contentMode: .fit)
            .frame(
                minWidth: 32,
                maxWidth: 80,
                minHeight: 32,
                maxHeight: 80
            )
                
            RotatingRingView(radius: 64, speed: 0.3, content: [
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                    GenerativeProfilePic(did: Did.dummyData(), size: 32),
                ])
                .opacity(0.75)
                .shadow(color: Color.brandDropShadow(colorScheme).opacity(0.25), radius: 4, x:0, y: 5)
                
            RotatingRingView(radius: 100, speed: 0.15, content: [
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                    GenerativeProfilePic(did: Did.dummyData(), size: 20),
                ])
                .opacity(0.4)
                .shadow(color: Color.brandDropShadow(colorScheme).opacity(0.25), radius: 4, x:0, y: 5)
            }
            .frame(width: 256, height: 256)
        }
    }
//}

struct FirstRunOrbitEffectView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunOrbitEffectView()
    }
}
