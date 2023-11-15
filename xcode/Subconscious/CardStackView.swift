import SwiftUI

struct CardView: View {
    var entry: EntryStub
//    var t: CGFloat
    
    static let colors: [Color] = [
        Color(red: 0.97, green: 0.49, blue: 0.75),
        Color(red: 0.56, green: 0.62, blue: 0.93),
        Color(red: 0.93, green: 0.59, blue: 0.56),
        Color(red: 0.74, green: 0.52, blue: 0.95),
        Color(red: 0.97, green: 0.75, blue: 0.48)
    ]
    var color: Color {
        Self.colors[abs(entry.hashValue) % Self.colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            BylineSmView(
                pfp: .generated(entry.did),
                slashlink: entry.address
            )
            
            SubtextView(subtext: entry.excerpt)
                .environment(\.openURL, OpenURLAction { url in
                    guard let subslashlink = url.toSubSlashlinkURL() else {
                        return .systemAction
                    }

                    return .handled
                })
            
            Spacer()
        }
        .padding(AppTheme.padding)
        .allowsHitTesting(false)
        .frame(width: 374, height: 420)
        .background(color)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
//            .scaleEffect(CGSize(width: 1.0, height: 1.0))
    }
}

struct CardStack: View {
    var cards: [EntryStub]
    var onSwipeRight: (EntryStub) -> Void
    var onSwipeLeft: (EntryStub) -> Void
    
    func indexOf(card: EntryStub) -> Int? {
        return cards.firstIndex(where: { $0.id == card.id })
    }
    
    @State var offsets: [EntryStub:CGFloat] = [:]
    @State var pointer: Int = 0
    
    func offset(`for`: EntryStub) -> CGFloat {
        offsets[`for`] ?? 0
    }
    
    func offset(for index: Int) -> CGFloat {
        if index < 0 || index >= cards.count {
            return 0
        }
        
        return offset(for: cards[index])
    }
    
    private static let THRESHOLD = 100.0
    
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
                        .rotationEffect(
                            index != pointer
                                ? .degrees(2.0*Double(sin(CGFloat(index) * 2.0)))
                                : .degrees(Double(offset(for: card) / 32.0))
                        )
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
                                                    if (offset(for: card) > 0) {
                                                        onSwipeRight(card)
                                                    } else {
                                                        onSwipeLeft(card)
                                                    }
                                                    
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
                        .animation(.easeOutCubic(duration: 0.2), value: pointer)
                    }
                }
            }
        }
        .overlay(
            Rectangle()
                .frame(width: 64, height: 200)
                .foregroundStyle(Color.red)
                .offset(x: 200, y: 0)
                .opacity(offset(for: pointer) / Self.THRESHOLD)
        )
        .overlay(
            Rectangle()
                .frame(width: 64, height: 200)
                .foregroundStyle(Color.blue)
                .offset(x: -200, y: 0)
                .opacity(-offset(for: pointer) / Self.THRESHOLD)
        )
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
        ], onSwipeRight: { _ in }, onSwipeLeft: { _ in })
    }
}
