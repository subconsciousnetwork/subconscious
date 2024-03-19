//
//  RewardCardView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct RewardCardView: View {
    var message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.title)
                .italic()
        }
        .padding(DeckTheme.cardPadding)
        .frame(
            minWidth: DeckTheme.cardSize.width,
            minHeight: DeckTheme.cardSize.height
        )
        .foregroundStyle(message.themeColor.toHighlightColor())
        .background(message.themeColor.toColor())
        .cornerRadius(DeckTheme.cornerRadius)
        .transition(.push(from: .bottom))
    }
}
