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
    @State private var cards: [ThemeColor] = ThemeColor.allCases
    @State private var offset: CGFloat = 0
    @State private var behind: Bool = false
    
    private static let duration = 0.3
    private static let pause = 0.2
    private static let size = CGSize(width: 64, height: 96)

    private func shuffleCards() async {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            // Move the front card up and out
            offset = -Self.size.height
        }
        
        try? await Task.sleep(for: .seconds(0.2))

        // Move card back down BEHIND the stack
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            offset = 0
        }
        
        withAnimation(Animation.easeInOut(duration: 0.3)) {
            behind = true
        }
        
        try? await Task.sleep(for: .seconds(Self.duration - 0.2))
        
        // Place the card at the back and show the next card
        withAnimation(DeckTheme.reboundSpring) {
            cards.append(cards.removeFirst())
            behind = false
        }
    }

    var body: some View {
        ZStack {
            ForEach(cards, id: \.self) { card in
                let zIndex = self.zIndexForCard(card: card)
                
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                    .fill(self.colorForCard(card: card))
                    .frame(width: Self.size.width, height: Self.size.height)
                    .offset(y: card == cards.first ? offset : 0)
                    .zIndex(card == cards.first && behind ? 0 : zIndex)
                    .scaleEffect(0.5 + zIndex / 10.0)
                    .rotation3DEffect(.degrees(2), axis: (1, 0, 0))
                    .shadow(
                        color: DeckTheme.cardShadow.opacity(
                            0.025 * zIndex
                        ),
                        radius: 1.5,
                        x: 0,
                        y: 1.5
                    )
            }
        }
        .onAppear {
            // Start the shuffle animation
            Timer.scheduledTimer(
                withTimeInterval: Self.duration + Self.pause,
                repeats: true
            ) { _ in
                Task {
                    await shuffleCards()
                }
            }
        }
    }

    private func colorForCard(card: ThemeColor) -> Color {
        card.toColor()
    }

    private func zIndexForCard(card: ThemeColor) -> Double {
        Double(cards.count) - Double((cards.firstIndex(of: card) ?? 0))
    }
}

struct CardShuffleView_Previews: PreviewProvider {
    static var previews: some View {
        CardShuffleView()
    }
}
