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

enum Progress {
    case inactive
    case started
    case changed
}

struct CardStack: View {
    var cards: [EntryStub]
    var pointer: Int
    var onSwipeRight: (EntryStub) -> Void
    var onSwipeLeft: (EntryStub) -> Void
    
    func indexOf(card: EntryStub) -> Int? {
        return cards.firstIndex(where: { $0.id == card.id })
    }
    
    @State var offsets: [EntryStub:CGFloat] = [:]
    @GestureState private var gestureState: Progress = .inactive
    
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
    var feedbackGenerator = UIImpactFeedbackGenerator()
    
    var swipeProgress: CGFloat {
        return abs(offset(for: pointer) / Self.THRESHOLD).clamp(min: 0.0, max: 1.0)
    }
    
    func rotation(for index: Int) -> Double {
        let fundamental = 4.0*Double(sin(CGFloat(index - pointer) * 5.0))
        let harmonic = 1.0*Double(sin(CGFloat(index) * 5.0))
        
        let distance = index - pointer
        
        return (fundamental + harmonic) * (1 - swipeProgress)
    }
    
    func rotation(t: CGFloat) -> Double {
        let newT = t + (swipeProgress / 80.0)
        let fundamental = 4.0*Double(sin(CGFloat(newT - 0.1) * 20.0))
        let harmonic = 1.0*Double(sin((newT - 0.1) * 10))
        
        let result = (fundamental + harmonic)
        
        if (newT < 0.01) {
            return (0.1 + 0.9*(max(0, newT) / 0.01)) * result
        } else {
            return result
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                let deck = Array(cards.enumerated().reversed())
                ForEach(deck, id: \.element.id) { index, card in
                    VStack {
                        if (index >= pointer - 1) {
                            let t = max(0, CGFloat(index - pointer)) / 16.0 - abs(offset(for: pointer) / Self.THRESHOLD) / 24.0
                            CardView(entry: card)
                                .scaleEffect(min(1, 1-t + 0.03))
                                .offset(x: offset(for: card), y: 0)
                                .rotationEffect(
                                    index != pointer
                                    ? .degrees(rotation(t: t))
                                    : .degrees(Double(offset(for: card) / 32.0))
                                )
                                .gesture(DragGesture()
                                    .updating(
                                        $gestureState,
                                        body: { (value, state, transaction) in
                                            switch state {
                                            case .inactive:
                                                state = .started
                                                feedbackGenerator.prepare()
                                                break
                                            case .started:
                                                state = .changed
                                                break
                                            case .changed:
                                                break
                                            }
                                        }
                                    )
                                    .onChanged { gesture in
                                        withAnimation(.interactiveSpring()) {
                                            offsets[card] = gesture.translation.width
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(duration: 0.4)) {
                                            if abs(offset(for: card)) > Self.THRESHOLD {
                                                // Swipe out the card
                                                offsets[card] = offset(for: card) > 0 ? 512 : -512
                                                
                                                withAnimation(.spring()) {
                                                    if (offset(for: card) > 0) {
//                                                        feedbackGenerator.impactOccurred()
                                                        onSwipeRight(card)
                                                    } else {
//                                                        feedbackGenerator.impactOccurred()
                                                        onSwipeLeft(card)
                                                    }
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
                                .animation(.spring(duration: 0.2), value: pointer)
                        }
                    }
                }
            }
            
            VStack {
                Text("\(pointer)/\(cards.count)")
                    .contentTransition(.numericText())
                Text("\(swipeProgress)")
                    .contentTransition(.numericText())
            }
            .font(.caption)
        }
        .overlay(
            Rectangle()
                .frame(width: 32, height: 200)
                .foregroundStyle(Color.red)
                .offset(x: 200, y: 0)
                .opacity(offset(for: pointer) / Self.THRESHOLD)
        )
        .overlay(
            Rectangle()
                .frame(width: 32, height: 200)
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
        ], pointer: 0, onSwipeRight: { _ in }, onSwipeLeft: { _ in })
    }
}
