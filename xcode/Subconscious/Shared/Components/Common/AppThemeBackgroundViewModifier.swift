//
//  AppThemeBackgroundViewModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 5/2/2024.
//

import SwiftUI

struct AppThemeBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        (colorScheme == .dark ? DeckTheme.darkBg : DeckTheme.lightBg)
            .ignoresSafeArea()
    }
}
