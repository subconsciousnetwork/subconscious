import SwiftUI

struct CardModel: Identifiable, Equatable {
    private let _id: UUID = UUID()
    var id: UUID { _id }
    
    var title: String
    var offset: CGSize = .zero
    var scale: CGFloat = 1
}

struct CardView: View {
    var title: String
//    var t: CGFloat
    
    var body: some View {
        Text("\(title)")
            .font(.largeTitle)
            .frame(width: 300, height: 400)
            .background(.blue)
            .cornerRadius(10)
            .shadow(radius: 5)
//            .scaleEffect(CGSize(width: 1.0, height: 1.0))
    }
}

struct CardStack: View {
    @State private var cards = [
        CardModel(title: "Card 1"),
        CardModel(title: "Card 2"),
        CardModel(title: "Card 3"),
        CardModel(title: "Card 4"),
        CardModel(title: "Card 5")
    ]
    
    func indexOf(card: CardModel) -> Int? {
        return cards.firstIndex(where: { $0.id == card.id })
    }
    
    var body: some View {
        VStack {
            Text("\(cards.count)")
                .contentTransition(.numericText())
            
            Button(action: {
                withAnimation(.spring()) {
                    cards.insert(CardModel(title: String.dummyDataShort()), at: cards.count)
                }
            }, label: {
                Text("Add Card")
            })
            ZStack {
                ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { index, card in
                    VStack {
                        let t = CGFloat(index) / 8.0
                        CardView(title: card.title)
                        .offset(x: 0, y: sqrt(t) * 20) // CGFloat(index) * -10)
                        .offset(x: card.offset.width, y: 0)
                        .opacity(1.0 - t)
                        .rotationEffect(.degrees(Double(card.offset.width / 32)))
                        .gesture(DragGesture()
                                    .onChanged { gesture in
                                        withAnimation(.spring()) {
                                            cards[index].offset.width = gesture.translation.width
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            if abs(cards[index].offset.width) > 100 {
                                                // Swipe out the card
                                                    cards[index].offset.width = cards[index].offset.width > 0 ? 512 : -512
                                                
                                                Task.detached {
                                                    try? await Task.sleep(nanoseconds: 20_000_000)
                                                    _ = withAnimation(.spring()) {
                                                        cards.remove(at: index)
                                                    }
                                                }
                                            } else {
                                                // Reset the card position
                                                cards[index].offset = .zero
                                            }
                                        }
                                    })
                        .zIndex(cards[indexOf(card: card) ?? 0].offset.width == 0 ? 0 : 1) // Bring card to front during drag
                    }
                }
            }
        }
    }
    
    func updateStack() {
        for i in 0..<cards.count {
            cards[i].scale = 1 - CGFloat(i) * 0.02
            withAnimation(.spring()) {
                cards[i].offset.height = CGFloat(i) * 10
            }
        }
    }
}


struct CardStack_Previews: PreviewProvider {
    static var previews: some View {
        CardStack()
    }
}
