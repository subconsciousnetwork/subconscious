//
//  RelatedNoteButtonStyle.swift
//  Subconscious
//
//  Created by Ben Follington on 5/2/2024.
//

import SwiftUI

struct RelatedNoteButtonStyle: ButtonStyle {
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
            .background(color)
            .overlay(
                Rectangle()
                    .fill(configuration.isPressed
                          ? Color.backgroundPressed
                          : Color.clear)
            )
            .contentShape(Self.roundedRect)
            .clipShape(Self.roundedRect)
            .cornerRadius(AppTheme.cornerRadiusLg, corners: .allCorners)
            .animation(.default, value: configuration.isPressed)
            .shadow(style: .transclude)
    }
}

struct RelatedNoteButtonStyle_Previews: PreviewProvider {
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
