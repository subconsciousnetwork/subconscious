//
//  TranscludeButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/16/23.
//

import SwiftUI

struct TranscludeButtonStyle: ButtonStyle {
    private var roundedRect = RoundedRectangle(
        cornerRadius: AppTheme.cornerRadiusLg
    )
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    func background(_ configuration: Configuration) -> Color {
        switch (colorScheme) {
        case .dark:
            return configuration.isPressed
                ? Color.backgroundPressed
                : Color.secondaryBackground
        case .light:
            return configuration.isPressed
                ? Color.backgroundPressed
                : Color.tertiarySystemGroupedBackground
        default:
            return Color.clear
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, AppTheme.unit3)
            .padding(.horizontal, AppTheme.unit4)
            .expandAlignedLeading()
            .background(
                background(configuration)
            )
            .contentShape(roundedRect)
            .clipShape(roundedRect)
            .animation(.default, value: configuration.isPressed)
    }
}

struct TranscludeButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(
            action: {},
            label: {
                Text("Test")
            }
        ).buttonStyle(
            TranscludeButtonStyle()
        )
    }
}
