//  Constants.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/10/21.
//
import SwiftUI
import os

struct Constants {
    static let rdns = "com.subconscious.Subconscious"

    static let logger = Logger(
        subsystem: rdns,
        category: "main"
    )

    struct Color {
        static let accent = SwiftUI.Color.accentColor
        static let background = SwiftUI.Color(.systemBackground)
        static let secondaryBackground = SwiftUI.Color(.secondarySystemBackground)
        static let text = SwiftUI.Color.primary
        static let secondaryText = SwiftUI.Color.secondary
        static let placeholderText = SwiftUI.Color(.placeholderText)
        static let link = accent
        static let inputBackground = secondaryBackground
        static let primaryButtonBackground = secondaryBackground
        static let primaryButtonPressedBackground = secondaryBackground
        static let primaryButtonDisabledBackground = secondaryBackground
        static let separator = SwiftUI.Color(.separator)
        static let icon = text
        static let secondaryIcon = secondaryText
        static let quotedText = accent
    }

    struct Theme {
        static let cornerRadius: Double = 12
        static let buttonHeight: CGFloat = 44
    }

    struct Duration {
        static let fast: Double = 0.128
        static let `default`: Double = 0.2
    }
}

extension Shadow {
    static let lightShadow = Shadow(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 0
    )
}
