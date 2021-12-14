//
//  TranscludeButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/27/21.
//

import SwiftUI

struct TranscludeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.horizontal, AppTheme.unit4)
            .padding(.vertical, AppTheme.unit3)
            .contentShape(Rectangle())
            .background(
                configuration.isPressed ?
                Color.secondaryBackgroundPressed :
                Color.secondaryBackground
            )
            .foregroundColor(!isEnabled ? Color.disabledText : Color.text)
            .cornerRadius(AppTheme.cornerRadius)
            .animation(
                .easeOut(duration: Duration.fast),
                value: configuration.isPressed
            )
    }
}
