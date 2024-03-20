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
          .shadow(style: .transclude)
          .transition(.push(from: .bottom))
    }
}

struct MiniCardStackView: View {
    var cards: [CardModel]
    
    var body: some View {
        ZStack {
            ForEach(cards.indices.reversed(), id: \.self) { idx in
                let card = cards[idx]
                let t = cards.count - idx
                if let entry = card.entry {
                    MiniCardView(color: entry.color)
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
                    Text("\(DeckModel.maxRewardCardBufferSize)")
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
