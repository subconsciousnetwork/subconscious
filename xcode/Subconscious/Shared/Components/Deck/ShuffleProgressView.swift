//
//  ShuffleProgressView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 5/1/2024.
//

import Foundation
import SwiftUI

struct CardShuffleView: View {
    @Environment (\.colorScheme) var colorScheme
    @State private var cards = [0, 1, 2, 3, 4]
    @State private var offset: CGFloat = 0
    @State private var behind: Bool = false
    
    public static let duration = 0.3

    private func shuffleCards() {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            // Move the front card up and out
            offset = -96
        }

        // Reset and move the front card to back after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                offset = 0
            }
        }
        
        // Reset and move the front card to back after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.3)) {
                behind = true
            }
        }
        
        // Reset and move the front card to back after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.duration) {
            withAnimation(DeckTheme.reboundSpring) {
                cards.append(cards.removeFirst())
                behind = false
            }
        }
    }

    var body: some View {
        ZStack {
            ForEach(cards, id: \.self) { card in
                let zIndex = self.zIndexForCard(card: card)
                
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                    .fill(self.colorForCard(card: card))
                    .frame(width: 64, height: 96)
                    .offset(y: card == cards.first ? offset : 0)
                    .zIndex(card == cards.first && behind ? 0 : zIndex)
                    .scaleEffect(0.5 + zIndex / 10.0)
                    .rotation3DEffect(.degrees(2), axis: (1, 0, 0))
                    .shadow(
                        color: DeckTheme.cardShadow.opacity(
                            0.035 * zIndex
                        ),
                        radius: 2.5,
                        x: 0,
                        y: 1.5
                    )
            }
        }
        .onAppear {
            // Start the shuffle animation
            Timer.scheduledTimer(
                withTimeInterval: CardShuffleView.duration + 0.2,
                repeats: true
            ) { _ in
                shuffleCards()
            }
        }
    }

    private func colorForCard(card: Int) -> Color {
        let colors = colorScheme == .dark
            ? DeckTheme.darkCardColors
            : DeckTheme.lightCardColors
        
        return colors[card]
    }

    private func zIndexForCard(card: Int) -> Double {
        return 5.0 - Double((cards.firstIndex(of: card) ?? 0))
    }
}

struct CardShuffleView_Previews: PreviewProvider {
    static var previews: some View {
        CardShuffleView()
    }
}
