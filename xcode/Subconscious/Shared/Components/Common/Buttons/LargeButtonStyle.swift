//
//  PrimaryButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct LargeButtonStyle: ButtonStyle {
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
            Color.chooseForState(
                isPressed: configuration.isPressed,
                isEnabled: isEnabled,
                normal: Color.primaryButtonBackground,
                pressed: Color.primaryButtonBackgroundPressed,
                disabled: Color.primaryButtonBackgroundDisabled
            )
        )
        .clipShape(Capsule())
        .padding(
            .horizontal, AppTheme.unit * 4
        )
        .animation(.default, value: configuration.isPressed)
    }
}

struct LargeButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(
            action: {},
            label: {
                Text("Floop")
            }
        ).buttonStyle(
            LargeButtonStyle()
        )
    }
}
