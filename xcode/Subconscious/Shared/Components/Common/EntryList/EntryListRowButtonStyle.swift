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
    var color: Color
    var padding: CGFloat = AppTheme.unit3
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(padding)
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
            .animation(.default, value: configuration.isPressed)
            .shadow(style: .transclude)
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
