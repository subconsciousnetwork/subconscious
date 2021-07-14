//
//  Colors.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/8/21.
//
import SwiftUI

extension Color {
    struct Sub {
        static let accent = Color.accentColor
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let text = Color.primary
        static let secondaryText = Color.secondary
        static let placeholderText = Color(.placeholderText)
        static let linkText = Color(.link)
        static let inputBackground = secondaryBackground
        static let buttonBackground = secondaryBackground
        static let separator = Color(.separator)
        static let icon = text
        static let secondaryIcon = secondaryText
        static let quotedText = accent
    }
}
