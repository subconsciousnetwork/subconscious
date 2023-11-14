import SwiftUI

struct CardView: View {
    var entry: EntryStub
//    var t: CGFloat
    
    var body: some View {
        TranscludeView(entry: entry, onRequestDetail: { }, onLink: { _ in })
            .allowsHitTesting(false)
            .frame(width: 300, height: 400)
            .background(Color.tertiarySystemGroupedBackground)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5)
//            .scaleEffect(CGSize(width: 1.0, height: 1.0))
    }
}

struct CardStack: View {
    var cards: [EntryStub]
    var onCardRemoved: (EntryStub) -> Void
    
    func indexOf(card: EntryStub) -> Int? {
        return cards.firstIndex(where: { $0.id == card.id })
    }
    
    @State var offset: CGFloat = 0.0
    
    var body: some View {
        VStack {
            Text("\(cards.count)")
                .contentTransition(.numericText())
            
            ZStack {
                let deck = Array(cards.enumerated().reversed())
                ForEach(deck, id: \.element.id) { index, card in
                    VStack {
                        let t = CGFloat(index) / 8.0
                        CardView(entry: card)
                        .offset(x: 0, y: sqrt(t) * 20) // CGFloat(index) * -10)
                        .offset(x: index == 0 ? offset : 0, y: 0)
                        .rotationEffect(index == 0 ? .degrees(Double(offset / 32)) : .degrees(0))
                        .gesture(DragGesture()
                                    .onChanged { gesture in
                                        withAnimation(.spring()) {
                                            offset = gesture.translation.width
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            if abs(offset) > 100 {
                                                // Swipe out the card
                                                offset = offset > 0 ? 512 : -512
                                                
                                                withAnimation(.spring()) {
                                                    onCardRemoved(card)
                                                    offset = 0
                                                }
                                            } else {
                                                // Reset the card position
                                                offset = 0
                                            }
                                        }
                                    })
                        .zIndex(offset == 0 ? 0 : 1) // Bring card to front during drag
                    }
                }
            }
        }
    }
    
//    func updateStack() {
//        for i in 0..<cards.count {
//            cards[i].scale = 1 - CGFloat(i) * 0.02
//            withAnimation(.spring()) {
//                cards[i].offset.height = CGFloat(i) * 10
//            }
//        }
//    }
}


struct CardStack_Previews: PreviewProvider {
    static var previews: some View {
        CardStack(cards: [
            EntryStub.dummyData(),
            EntryStub.dummyData(),
            EntryStub.dummyData(),
            EntryStub.dummyData(),
        ], onCardRemoved: { _ in })
    }
}
