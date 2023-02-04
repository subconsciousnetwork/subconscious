//
//  PrimaryButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .frame(
                height: AppTheme.unit * 8
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
            .padding(
                .horizontal, AppTheme.unit * 4
            )
            .background(
                Color.chooseForState(
                    isPressed: configuration.isPressed,
                    isEnabled: isEnabled,
                    normal: Color.primaryButtonBackground,
                    pressed: Color.primaryButtonBackgroundPressed,
                    disabled: Color.primaryButtonBackgroundDisabled
                )
            )
            .clipShape(Capsule())
            .animation(.default, value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(
            action: {},
            label: {
                Text("Floop")
            }
        ).buttonStyle(
            PrimaryButtonStyle()
        )
    }
}
