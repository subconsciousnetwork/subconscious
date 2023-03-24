//
//  ProgressTorusView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/24/23.
//

import SwiftUI

struct ProgressTorusView<Inner: View>: View {
    private let gradient = AngularGradient.conicGradient(
        Gradient(
            stops: [
                Gradient.Stop(
                    color: .brandMarkPurple.opacity(0.0),
                    location: 0.6
                ),
                Gradient.Stop(color: .brandMarkRed, location: 1.0),
            ]
        ),
        center: .center
    )

    @State private var isAnimating = false
    var isComplete = false
    var size: CGFloat = 256
    var duration: Double = 1
    var inner: () -> Inner
    
    var body: some View {
        VStack {
            inner()
                .scaleEffect(
                    isAnimating && !isComplete ? 0.9 : 1,
                    anchor: .center
                )
                .animation(
                    Animation
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .overlay(alignment: .center) {
                    Circle().stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(
                        width: size,
                        height: size
                    )
                    .opacity(isComplete ? 0 : 1)
                    .rotationEffect(
                        Angle(degrees: isAnimating ? 360.0 : 0.0)
                    )
                    .animation(
                        Animation
                            .linear(duration: duration)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                }
        }
        .frame(width: size, height: size)
    }
}


struct ProgressTorusView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressTorusView(
            inner: {
                Image("sub_logo_light")
                    .resizable()
                    .frame(width: 200, height: 200)
            }
        )
    }
}
