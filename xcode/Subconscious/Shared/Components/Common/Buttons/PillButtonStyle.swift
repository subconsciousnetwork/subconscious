//
//  PillButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

enum PillButtonSize {
    case small
    case regular
}

struct PillButtonView: View {
    var size: PillButtonSize
    var label: ButtonStyleConfiguration.Label
    
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            label
                .font(
                    Func.run {
                        switch (size) {
                        case .regular:
                            return .body
                        case .small:
                            return .caption
                        }
                    }
                )
            Spacer(minLength: 0)
        }
        .bold()
        .frame(
            height: Func.run {
                switch (size) {
                case .regular:
                    return AppTheme.unit * 12
                case .small:
                    return AppTheme.unit * 8
                }
            }
        )
        
    }
}

struct PillButtonStyle: ButtonStyle {
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
        .frame(minHeight: AppTheme.minTouchSize)
    }
}

struct PillButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                Button(
                    action: {},
                    label: {
                        Text("Floop")
                    }
                ).buttonStyle(
                    PillButtonStyle(size: .small)
                )
            }
            Button(
                action: {},
                label: {
                    Text("Floop")
                }
            ).buttonStyle(
                PillButtonStyle()
            )
        }
    }
}
