//
//  TranscludeButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/16/23.
//

import SwiftUI

struct TranscludeButtonStyle: ButtonStyle {
    private static let roundedRect = RoundedRectangle(
        cornerRadius: AppTheme.cornerRadiusLg
    )
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, AppTheme.unit3)
            .padding(.horizontal, AppTheme.unit3)
            .expandAlignedLeading()
            .background(
                color.opacity(colorScheme == .dark ? 0.5 : 1)
            )
            .overlay(
                Rectangle()
                    .fill(configuration.isPressed
                          ? Color.backgroundPressed
                          : Color.clear)
            )
            .contentShape(Self.roundedRect)
            .clipShape(Self.roundedRect)
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
            TranscludeButtonStyle(color: Color.secondary)
        )
    }
}
