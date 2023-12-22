//
//  PaletteButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/21/23.
//

import SwiftUI

struct PaletteButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var size: CGFloat = AppTheme.unit * 18
    var theme = Color.ButtonRoleTheme(
        normal: Color.ButtonTheme(
            normal: Color.Theme(
                foreground: Color.buttonText,
                background: Color.secondaryBackground
            ),
            pressed: Color.Theme(
                foreground: Color.buttonText,
                background: Color.secondaryBackground.opacity(0.5)
            ),
            disabled: Color.Theme(
                foreground: Color.disabled,
                background: Color.secondaryBackground
            )
        ),
        destructive: Color.ButtonTheme(
            normal: Color.Theme(
                foreground: Color.brandMarkRed,
                background: Color.brandMarkRed.opacity(0.1)
            ),
            pressed: Color.Theme(
                foreground: Color.brandMarkRed,
                background: Color.brandMarkRed.opacity(0.05)
            ),
            disabled: Color.Theme(
                foreground: Color.disabled,
                background: Color.secondaryBackground
            )
        )
    )

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .labelStyle(PaletteLabelStyle())
        }
        .frame(
            width: size,
            height: size
        )
        .theme(
            theme.forRole(configuration.role),
            isPressed: configuration.isPressed,
            isEnabled: isEnabled
        )
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct PaletteLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .frame(width: AppTheme.icon, height: AppTheme.icon)
                .padding(.bottom, AppTheme.unitHalf)
            configuration.title
                .font(.caption)
        }
        .padding(AppTheme.unit2)
    }
}

struct PaletteButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            Button(
                action: {},
                label: {
                    Label(
                        title: { Text("Label") },
                        icon: { Image(systemName: "doc.on.doc") }
                    )
                }
            )
            .buttonStyle(PaletteButtonStyle())
            Button(
                role: .destructive,
                action: {},
                label: {
                    Label(
                        title: { Text("Label") },
                        icon: { Image(systemName: "trash") }
                    )
                }
            )
            .buttonStyle(PaletteButtonStyle())
        }
    }
}
