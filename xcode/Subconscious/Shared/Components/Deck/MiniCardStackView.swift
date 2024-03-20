//
//  MiniCardStackView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2024.
//

import SwiftUI

struct MiniCardView: View {
    var color: Color
    
    var body: some View {
        Rectangle()
          .foregroundColor(.clear)
          .frame(width: 32, height: 44)
          .background(color)
          .cornerRadius(4)
          .shadow(color: Color(red: 0.19, green: 0.09, blue: 0.33).opacity(0.2), radius: 1.5, x: 0, y: 1.5)
          .rotationEffect(Angle(degrees: 0))
          .transition(.push(from: .bottom))
    }
}

extension Angle {
    static func percent(_ percent: Double) -> Angle {
        Angle(degrees: percent * 360)
    }
}

struct SummoningCircleView: View {
    var radius: CGFloat = 64
    var speed: CGFloat = 1
    var namespace: Namespace.ID
    var cards: [CardModel]
    @State var playedCards: [CardModel] = []
    
    func delta(_ idx: Int) -> Double {
        (Double(cards.count - 1) / 2.0) - Double(idx)
    }
    
    var body: some View {
        HStack(spacing: AppTheme.unit2) {
            ForEach(playedCards.indices, id: \.self) { index in
                let card = playedCards[index]
                if let entry = card.entry {
                    MiniCardView(color: entry.color)
                        .scaleEffect(x: 1.5, y: 1.5)
                        .matchedGeometryEffect(id: entry.id, in: namespace)
                        .rotationEffect(.degrees(delta(index) * -4))
                        .offset(y: abs(delta(index)) * 2)
                        .animation(.interactiveSpring(), value: cards)
                }
            }
        }
        .task {
            playedCards.removeAll()
            for card in cards {
                playedCards.append(card)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        .onChange(of: cards) { _, _ in
            while cards.count > playedCards.count {
                playedCards.append(cards[playedCards.count])
            }
            
            while cards.count < playedCards.count {
                playedCards.removeLast()
            }
        }
        .animation(.interactiveSpring(), value: playedCards)
        .animation(.interactiveSpring(), value: cards)
    }
}

struct MiniCardStackView: View {
    var cards: [CardModel]
    @Namespace var namespace
    
    var body: some View {
        ZStack {
            ForEach(cards.indices.reversed(), id: \.self) { idx in
                let card = cards[idx]
                let t = cards.count - idx
                if let entry = card.entry {
                    MiniCardView(color: entry.color)
                        .matchedGeometryEffect(id: entry.id, in: namespace)
                        .rotationEffect(.degrees(Double(-8 + 5 * Double(idx))))
                        .offset(x: 0, y: CGFloat(t * 2))
                        .zIndex(Double(idx))
                        .opacity(1 - Double(t) * 0.2)
                }
            }
            
            if !cards.isEmpty {
                HStack(alignment: .bottom, spacing: 1) {
                    Text("\(cards.count)").contentTransition(.numericText())
                        .bold()
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .offset(x: -0.5, y: -2)
                    Text("/")
                        .font(.system(size: 10.0))
                        .foregroundColor(.secondary)
                        .bold()
                        .opacity(0.25)
                        .offset(x: 0.5, y: 0.5)
                    Text("4")
                        .font(.system(size: 8.0))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.75)
                        .offset(x: 1, y: 4.5)
                }
                .zIndex(Double(cards.count))
                .offset(x: 1.5, y: 0.5)
            }
        }
        .animation(DeckTheme.reboundSpring, value: cards)
    }
}

struct MiniCardStackView_Previews: PreviewProvider {
    struct TestView: View {
        @State var cards: [CardModel] = []
        
        var body: some View {
            VStack {
                Spacer()
                
                MiniCardStackView(cards: cards)
                
                Spacer()
                
                Button(action: {
                    cards.append(
                        CardModel(
                            card: .prompt(
                                message: "Hello world",
                                entry: EntryStub.dummyData(),
                                author: UserProfile.dummyData(),
                                related: []
                            ),
                            liked: false
                        )
                    )
                },
                       label: {
                    Text("Add Card")
                })
                
                Button(action: {
                    cards.removeLast()
                },
                       label: {
                    Text("Remove Card")
                })
                
                Spacer()
            }
        }
    }
    
    static var previews: some View {
        TestView()
            .previewLayout(.sizeThatFits)
            .padding(10)
    }
}
