//
//  LargeGhostButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/3/2023.
//

import SwiftUI

struct LargeGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .bold()
        .frame(
            height: AppTheme.unit * 12
        )
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
        .clipShape(Capsule())
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
        .animation(.default, value: configuration.isPressed)
    }
}

struct LargeGhostButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(
            action: {},
            label: {
                Text("Floop")
            }
        ).buttonStyle(
            LargeGhostButtonStyle()
        )
    }
}
