//
//  AudienceSelectorButton.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct AudienceSelectorButton: View {
    var action: () -> Void
    var text: String

    var body: some View {
        Button(action: action) {
            Text(text)
        }
        .buttonStyle(AudienceSelectorButtonStyle())
    }
}

struct AudienceSelectorButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AppTheme.unit) {
            configuration.label
                .bold()
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
        }
        .frame(height: AppTheme.unit * 8)
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
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.accentColor, lineWidth: 1)
                .frame(height: AppTheme.unit * 6)
        )
        .animation(.default, value: configuration.isPressed)
    }
}

struct AudienceSelectorButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        AudienceSelectorButton(
            action: {},
            text: "Public"
        )
    }
}
