//
//  FABButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/14/21.
//

import SwiftUI

struct FABButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .foregroundColor(Color.fabBackground)
                .frame(
                    width: 56,
                    height: 56,
                    alignment: .center
                )
                .shadow(
                    radius: 8,
                    x: 0,
                    y: 4
                )
            configuration.label
                .foregroundColor(
                    isEnabled ? Color.fabText : Color.fabTextDisabled
                )
                .contentShape(
                    Circle()
                )
        }
        .scaleEffect(configuration.isPressed ? 0.8 : 1, anchor: .center)
        .animation(
            .easeOutCubic(duration: Duration.fast),
            value: configuration.isPressed
        )
        .transition(
            .opacity.combined(
                with: .scale(scale: 0.8, anchor: .center)
            )
        )
    }
}
