//
//  AppThemeToolbarViewModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 5/2/2024.
//

import SwiftUI

struct AppThemeToolbarViewModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .toolbarBackground(
                colorScheme == .dark
                    ? DeckTheme.darkBgStart
                    : DeckTheme.lightBgStart,
                for: .navigationBar
            )
            .toolbarBackground(
                colorScheme == .dark
                    ? DeckTheme.darkBgEnd
                    : DeckTheme.lightBgEnd,
                for: .tabBar
            )
    }
}
