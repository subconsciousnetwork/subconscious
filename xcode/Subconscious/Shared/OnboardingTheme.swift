//
//  OnboardingTheme.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 10/5/2023.
//

import Foundation
import SwiftUI

enum OnboardingTheme {}

extension OnboardingTheme {
    static let appBackgroundGradientLight = LinearGradient(
        gradient: Gradient(
            colors: [.brandBgTan, .white, .brandBgBlush]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let appBackgroundGradientDark = LinearGradient(
        gradient: Gradient(
            colors: [.brandBgBlack, .brandBgSlate, .brandBgPurple]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func appBackgroundGradient(
        _ colorScheme: ColorScheme
    ) -> LinearGradient {
        switch (colorScheme) {
        case .dark:
            return appBackgroundGradientDark
        default:
            return appBackgroundGradientLight
        }
    }
    
    static let shadowSize: CGFloat = 72
    static let heroIconSize: CGFloat = 180
    
    static func shadow(
        _ colorScheme: ColorScheme
    ) -> Color {
        switch (colorScheme) {
        case .dark:
            return .brandBgPurple
        default:
            return .brandMarkPink
        }
    }
}
