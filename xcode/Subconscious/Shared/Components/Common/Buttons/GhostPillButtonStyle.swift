//
//  LargeGhostButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/3/2023.
//

import SwiftUI

struct GhostPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var size: PillButtonSize = .regular

    func makeBody(configuration: Configuration) -> some View {
        PillButtonView(size: size, label: configuration.label)
            .foregroundColor(
                Color.chooseForState(
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    normal: Color.primaryButtonText,
                    pressed: Color.primaryButtonTextPressed,
                    disabled: Color.primaryButtonTextDisabled
                )
            )
            .background(
                Color.clear
            )
            .overlay(
                Capsule().stroke().foregroundColor(
                    Color.chooseForState(
                        isPressed: configuration.isPressed,
                        isEnabled: isEnabled,
                        normal: Color.primaryButtonBackground,
                        pressed: Color.primaryButtonBackgroundPressed,
                        disabled: Color.primaryButtonBackgroundDisabled
                    )
                )
            )
    }
}

struct GhostPillButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(
                action: {},
                label: {
                    Text("Floop")
                }
            ).buttonStyle(
                GhostPillButtonStyle()
            )
            Button(
                action: {},
                label: {
                    Text("Floop")
                }
            ).buttonStyle(
                GhostPillButtonStyle(size: .small)
            )
        }
    }
}
