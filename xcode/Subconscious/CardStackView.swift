import SwiftUI

struct CardView: View {
    var entry: CardModel
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
            switch entry.card {
            case .entry(let entry):
                SubtextView(subtext: entry.excerpt)
                    .environment(\.openURL, OpenURLAction { url in
                        guard let subslashlink = url.toSubSlashlinkURL() else {
                            return .systemAction
                        }

                        return .handled
                    })
                .foregroundStyle(.primary)
                .blendMode(.plusDarker)
            case .action(let string):
                VStack {
                    Image(systemName: "scribble.variable")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                    Text(string)
                }
                .foregroundStyle(.secondary)
                .blendMode(.plusDarker)
            }
            
            Spacer()
        }
        .padding(AppTheme.padding * 1.5)
        .allowsHitTesting(false)
        .frame(width: 374 - 0, height: 420 - 0)
        .background(color)
        .cornerRadius(32)
        .shadow(color: Color(red: 0.45, green: 0.25, blue: 0.75).opacity(0.25), radius: 4, x: 0, y: 2)
//            .scaleEffect(CGSize(width: 1.0, height: 1.0))
    }
}

enum Progress {
    case inactive
    case started
    case changed
}

struct CardStack: View {
    var cards: [CardModel]
    var pointer: Int
    var onSwipeRight: (CardModel) -> Void
    var onSwipeLeft: (CardModel) -> Void
    var onPickUpNote: () -> Void
    var onCardReleased: () -> Void
    
    func indexOf(card: CardModel) -> Int? {
        return cards.firstIndex(where: { $0.id == card.id })
    }
    
    @State var offsets: [CardModel:CGSize] = [:]
    @GestureState private var gestureState: Progress = .inactive
    
    func offset(`for`: CardModel) -> CGSize {
        offsets[`for`] ?? CGSize.zero
    }
    
    func offset(for index: Int) -> CGSize {
        if index < 0 || index >= cards.count {
            return CGSize.zero
        }
        
        return offset(for: cards[index])
    }
    
    private static let THRESHOLD = 128.0
    
    var swipeProgress: CGFloat {
        return (offset(for: pointer).width / Self.THRESHOLD).clamp(min: -1.0, max: 1.0)
    }
    
    func rotation(for index: Int) -> Double {
        let t = max(0, CGFloat(index - pointer)) / 16.0 + (swipeProgress) / 64.0
        let newT = t
        let fundamental = 6.0*Double(sin(CGFloat(newT - 0.1) * 40))
        let harmonic = 2.0*Double(sin((newT - 0.45) * 10))
        
        let result = (fundamental + harmonic)
        
        return result + (t * swipeProgress * 5)
    }
    
    func rotation(t: CGFloat) -> Double {
        let newT = t
        let fundamental = 4.0*Double(sin(CGFloat(newT - 1) * 5))
        let harmonic = 1.0*Double(sin((newT - 0.45) * 10))
        
        let result = (fundamental + harmonic)
        
        return result + (t * swipeProgress / 80.0)
    }
    
    var body: some View {
        VStack {
            ZStack {
                let deck = Array(cards.enumerated().reversed())
                ForEach(deck, id: \.element.id) { index, card in
                        if (index >= pointer - 1 && index < pointer + 5) {
                        VStack {
                            let t = max(0, CGFloat(index - pointer)) / 16.0 - abs(swipeProgress) / 64.0
                            CardView(entry: card)
                                .scaleEffect(max(0,min(1, 1-t + 0.03)))
                                .blur(radius: (0.33-swipeProgress*t)*5*max(0,min(1, 10*t + 0.03)))
                                .rotation3DEffect(
                                    .degrees(-swipeProgress * 100.0 * (0.1-t)), axis: (offset(for: card).height / 100.0, 1, 0), perspective: 0.5)
                                .offset(x: offset(for: card).width, y: offset(for: card).height / 4.0)
                                .rotationEffect(
                                    index != pointer
                                    ? .degrees(rotation(for: index))
                                    : .degrees(Double(offset(for: card).width / 32.0))
                                )
                                .gesture(DragGesture()
                                    .updating(
                                        $gestureState,
                                        body: { (value, state, transaction) in
                                            switch state {
                                            case .inactive:
                                                state = .started
                                                onPickUpNote()
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
                                            offsets.removeAll()
                                            offsets[card] = gesture.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                                            let offset = offset(for: card).width
                                            if abs(offset) > Self.THRESHOLD {
                                                // Swipe out the card
                                                offsets[card]?.width = offset > 0 ? 1024 : -1024
                                                
                                                withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                                                    if (offset > 0) {
                                                        onSwipeRight(card)
                                                    } else {
                                                        onSwipeLeft(card)
                                                    }
                                                }
                                            } else {
                                                // Reset the card position
                                                offsets[card] = CGSize.zero
                                                onCardReleased()
                                            }
                                        }
                                    })
                                .zIndex(offset(for: card).width == 0 ? 0 : 1) // Bring card to front during drag
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
            .foregroundStyle(.secondary)
        }
        .overlay(
            Rectangle()
                .frame(width: 16, height: 400)
                .foregroundStyle(Color.brandMarkPink)
                .offset(x: 200, y: 0)
                .blur(radius: 16)
                .blendMode(.screen)
                .opacity(swipeProgress)
        )
        .overlay(
            Rectangle()
                .frame(width: 16, height: 400)
                .foregroundStyle(Color.brandMarkPink)
                .offset(x: -200, y: 0)
                .blur(radius: 16)
                .blendMode(.plusDarker)
                .opacity(-swipeProgress)
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
        CardStack(
            cards: [
                CardModel(card: .entry(EntryStub.dummyData())),
                CardModel(card: .entry(EntryStub.dummyData())),
                CardModel(card: .entry(EntryStub.dummyData())),
                CardModel(card: .entry(EntryStub.dummyData())),
                CardModel(card: .entry(EntryStub.dummyData()))
            ],
            pointer: 0,
            onSwipeRight: { _ in },
            onSwipeLeft: { _ in },
            onPickUpNote: { },
            onCardReleased: { }
        )
    }
}
