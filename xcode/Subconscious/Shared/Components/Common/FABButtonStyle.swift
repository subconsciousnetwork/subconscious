//
//  FABButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/14/21.
//

import SwiftUI

struct FABButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .foregroundColor(
                    configuration.isPressed ?
                    Color.fabBackgroundPressed :
                    Color.fabBackground
                )
                .frame(
                    width: 56,
                    height: 56,
                    alignment: .center
                )
                .shadow(
                    radius: 8,
                    x: 0,
                    y: 4
                )
            configuration.label
                .foregroundColor(
                    isEnabled ? Color.fabText : Color.fabTextDisabled
                )
                .contentShape(
                    Circle()
                )
        }
    }
}
