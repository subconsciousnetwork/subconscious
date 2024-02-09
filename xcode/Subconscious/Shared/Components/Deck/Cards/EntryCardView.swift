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
    var liked: Bool
    var related: Set<EntryStub>
    var notify: (CardNotification) -> Void
    
    var background: Color {
        entry.color
    }
    
    var body: some View {
        CardContentView(
            entry: entry,
            liked: liked,
            related: related,
            notify: notify
        )
        .allowsHitTesting(false)
        .background(background)
        .cornerRadius(DeckTheme.cornerRadius)
    }
}
