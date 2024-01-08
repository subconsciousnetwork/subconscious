//
//  EntryCardView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct EntryCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var entry: EntryStub
    var related: Set<EntryStub>
    var onLink: (EntryLink) -> Void
    
    var background: Color {
        entry.color(colorScheme: colorScheme)
    }
    
    var body: some View {
        CardContentView(
            entry: entry,
            related: related,
            onLink: onLink
        )
        .allowsHitTesting(false)
        .background(background)
        .cornerRadius(DeckTheme.cornerRadius)
    }
}
