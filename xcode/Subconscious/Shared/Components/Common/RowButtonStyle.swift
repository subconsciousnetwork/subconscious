//
//  RowButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/27/21.
//

import Foundation
import SwiftUI

struct RowButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .background(
                configuration.isPressed ?
                Color.pressedBackground :
                Color.background
            )
            .foregroundColor(
                !isEnabled ?
                Color.disabledText :
                (configuration.isPressed ? Color.pressedText : Color.text)
            )
            .animation(
                .easeOut(duration: Duration.fast),
                value: configuration.isPressed
            )
    }
}
