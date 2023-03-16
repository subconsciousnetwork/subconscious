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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, AppTheme.unit3)
            .padding(.horizontal, AppTheme.unit4)
            .expandAlignedLeading()
            .background(
                configuration.isPressed ?
                    Color.backgroundPressed : Color.clear
            )
            .contentShape(roundedRect)
            .clipShape(roundedRect)
            .overlay(roundedRect.stroke(Color.separator, lineWidth: 0.5))
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
