//
//  EntryListRowButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 5/12/2023.
//

import Foundation
import SwiftUI

struct EntryListRowButtonStyle: ButtonStyle {
    private static let roundedRect = RoundedRectangle(
        cornerRadius: AppTheme.cornerRadiusLg
    )
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(AppTheme.unit2)
            .expandAlignedLeading()
            .background(
                color
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
            .shadow(color: DeckTheme.cardShadow.opacity(0.15), radius: 1.5, x: 0, y: 1.5)
    }
}

struct EntryListRowButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(
                action: {},
                label: {
                    Text("Test")
                }
            ).buttonStyle(
                EntryListRowButtonStyle(color: .secondaryBackground)
            )
        }
    }
}
