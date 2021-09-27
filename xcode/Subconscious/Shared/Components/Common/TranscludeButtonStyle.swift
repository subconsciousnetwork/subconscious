//
//  TranscludeButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/27/21.
//

import Foundation
import SwiftUI

struct TranscludeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(AppTheme.padding)
            .contentShape(Rectangle())
            .background(
                configuration.isPressed ?
                Color.secondaryBackground.opacity(0.5) :
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
