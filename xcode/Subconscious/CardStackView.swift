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
    
    @State var offsets: [EntryStub:CGFloat] = [:]
    @State var pointer: Int = 0
    
    func offset(`for`: EntryStub) -> CGFloat {
        offsets[`for`] ?? 0
    }
    
    var body: some View {
        VStack {
            Text("\(cards.count)")
                .contentTransition(.numericText())
            
            ZStack {
                let deck = Array(cards.enumerated().reversed())
                ForEach(deck, id: \.element.id) { index, card in
                    VStack {
                        let t = max(0, CGFloat(index - pointer)) / 8.0
                        CardView(entry: card)
                        .offset(x: 0, y: sqrt(t) * 20) // CGFloat(index) * -10)
                        .offset(x: offset(for: card), y: 0)
                        .rotationEffect(.degrees(Double(offset(for: card) / 32.0)))
                        .gesture(DragGesture()
                                    .onChanged { gesture in
                                        withAnimation(.interactiveSpring()) {
                                            offsets[card] = gesture.translation.width
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(duration: 0.4)) {
                                            if abs(offset(for: card)) > 100 {
                                                // Swipe out the card
                                                offsets[card] = offset(for: card) > 0 ? 512 : -512
                                                
                                                withAnimation(.spring()) {
                                                    onCardRemoved(card)
                                                    pointer += 1
                                                }
                                            } else {
                                                // Reset the card position
                                                offsets[card] = 0
                                            }
                                        }
                                    })
                        .zIndex(offset(for: card) == 0 ? 0 : 1) // Bring card to front during drag
                        .disabled(index != pointer)
                        .opacity(index >= pointer ? 1 : 0)
                        .animation(.easeOutCubic(duration: 0.1), value: pointer)
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
