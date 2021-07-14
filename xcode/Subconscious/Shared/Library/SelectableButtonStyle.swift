//
//  SelectableButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/13/21.
//
import SwiftUI
import Foundation

struct SelectableButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(
                configuration.isPressed ?
                Color.Sub.pressedBackground :
                Color.clear
            )
    }
}
