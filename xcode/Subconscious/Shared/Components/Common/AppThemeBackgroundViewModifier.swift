//
//  AppThemeBackgroundViewModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 5/2/2024.
//

import SwiftUI

struct AppThemeBackgroundViewModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                colorScheme == .dark ? DeckTheme.darkBg : DeckTheme.lightBg
            )
    }
}
