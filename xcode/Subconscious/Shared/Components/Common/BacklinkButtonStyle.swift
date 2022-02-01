//
//  BacklinkButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/27/21.
//

import SwiftUI

struct BacklinkButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.horizontal, AppTheme.unit4)
            .padding(.vertical, AppTheme.unit3)
            .contentShape(Rectangle())
            .background(
                configuration.isPressed ?
                Color.backgroundPressed :
                Color.clear
            )
            .foregroundColor(!isEnabled ? Color.textDisabled : Color.text)
            .animation(
                .easeOutCubic(duration: Duration.fast),
                value: configuration.isPressed
            )
    }
}
