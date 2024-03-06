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

struct CircleSliceView: View {
    var startAngle: Angle
    var endAngle: Angle
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width: CGFloat = min(geometry.size.width, geometry.size.height)
                let height = width
                
                let center = CGPoint(x: width * 0.5, y: height * 0.5)
                
                path.move(to: center)
                
                path.addArc(
                    center: center,
                    radius: width * 0.5,
                    startAngle: Angle(degrees: -90.0) + startAngle,
                    endAngle: Angle(degrees: -90.0) + endAngle,
                    clockwise: false)
                
            }
            .fill(color)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

extension Angle {
    static func percent(_ percent: Double) -> Angle {
        Angle(degrees: percent * 360)
    }
}

enum MiniCardStackViewMode {
    case stack
    case ring
    case combine
    case present
}

struct BouncySpringScaleEffectView: View {
    @State private var scale: CGFloat = 0 // Initial scale is set to 0
    
    var body: some View {
        VStack {
            Text("Presented content!")
        }
        .frame(width: 320, height: 128)
        .background(ThemeColor.b.toColor())
        .cornerRadius(DeckTheme.cornerRadius, corners: .allCorners)
        .scaleEffect(scale) // Apply the scale effect
        .onAppear {
            // Trigger the animation to its final state when the view appears
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                scale = 1 // Final scale is set to 1
            }
        }
        .shadow(style: .transclude)
    }
}

struct SummoningCircleView: View {
    var radius: CGFloat = 64
    var speed: CGFloat = 1
    var namespace: Namespace.ID
    @Binding var cards: [CardModel]
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
        .onChange(of: cards) { _ in
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
    @Binding var cards: [CardModel]
    @Binding var mode: MiniCardStackViewMode
    @Namespace var namespace
    
    var body: some View {
        switch mode {
        case .stack:
            ZStack {
                ForEach(cards.indices, id: \.self) { idx in
                    let card = cards[idx]
                    if let entry = card.entry {
                        MiniCardView(color: entry.color)
                            .matchedGeometryEffect(id: entry.id, in: namespace)
                            .rotationEffect(.degrees(Double(-8 + 12 * sqrt(Double(idx)))))
//                            .offset(x: 0, y: CGFloat(idx * 1))
                            .zIndex(Double(-idx))
                            .opacity(1 - Double(idx) * 0.33)
                    }
                }
    //
    //            CircleSliceView(
    //                startAngle: .degrees(0),
    //                endAngle: .percent(Double(cards.count) / 5.0),
    //                color: cards.first?.entry?.highlightColor ?? .secondary
    //            )
    //            .frame(
    //                width: 16,
    //                height: 16
    //            )
                
                Text("\(cards.count)").contentTransition(.numericText())
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
            }
            .animation(.interactiveSpring(), value: cards)
        case .ring:
            SummoningCircleView(
                radius: 64,
                speed: 1,
                namespace: namespace,
                cards: $cards
            )
        case .combine:
            ZStack {
                ForEach(cards.indices, id: \.self) { idx in
                    let card = cards[idx]
                    if let entry = card.entry {
                        MiniCardView(color: entry.color)
                            .matchedGeometryEffect(id: entry.id, in: namespace)
                            .rotationEffect(.degrees(Double(-8 + 12 * sqrt(Double(idx)))))
                            .offset(x: 0, y: CGFloat(idx * 1))
                            .zIndex(Double(-idx))
                            .opacity(0)
                    }
                }
            }
            .animation(.interactiveSpring(), value: cards)
            .animation(.interactiveSpring(), value: mode)
        case .present:
            ZStack {
//                Rectangle()
//                    .frame(width: 320, height: 128)
//                    .background(.red)
//                    .transition(.push(from: .bottom))
                
                BouncySpringScaleEffectView()
            }
            .animation(.interactiveSpring(), value: mode)
        }
        
    }
}

struct MiniCardStackView_Previews: PreviewProvider {
    struct TestView: View {
        @State var cards: [CardModel] = []
        @State var mode: MiniCardStackViewMode = .stack
        
        var body: some View {
            VStack {
                Spacer()
                
                MiniCardStackView(
                    cards: $cards,
                    mode: $mode
                )
                
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
                
                Button(action: {
                    withAnimation(.interactiveSpring) {
                        mode = .ring
                    }
                },
                       label: {
                    Text("Splay")
                })
                
                Button(action: {
                    withAnimation(.interactiveSpring) {
                        mode = .stack
                    }
                },
                       label: {
                    Text("Stack")
                })
                
                Button(action: {
                    Task {
                        withAnimation(.interactiveSpring) {
                            mode = .ring
                        }
                        
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        
                        withAnimation(.interactiveSpring) {
                            mode = .combine
                        }
                        
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        
                        withAnimation(.interactiveSpring) {
                            mode = .present
                            cards.removeAll()
                        }
                    }
                },
                       label: {
                    Text("Combine")
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
