import SwiftUI

struct CardView: View {
    var entry: CardModel
    @Environment(\.colorScheme) var colorScheme
    
    var colors: [Color] {
        colorScheme == .dark
            ? DeckTheme.darkCardColors
            : DeckTheme.lightCardColors
    }
    var color: Color {
        colors[abs(entry.hashValue) % colors.count]
    }
    
    var blendMode: BlendMode {
        colorScheme == .dark
           ? .plusLighter
           : .plusDarker
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit2) {
            switch entry.card {
            case let .entry(entry, _, backlinks):
                SubtextView(subtext: entry.excerpt)
                    // Opacity allows blendMode to work
                    .foregroundStyle(.primary.opacity(0.8))
                
                Spacer()
                
                HStack {
                    // Consider: should the date go here?
                    Text(
                        entry.address.markup
                    )
                    .lineLimit(1)
                    
                    if !backlinks.isEmpty {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "link")
                            Text("\(backlinks.count)")
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            case .action(let string):
                // TEMP
                VStack {
                    Image(systemName: "scribble.variable")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                    Text(string)
                }
                .foregroundStyle(.secondary)
            }
            
        }
        .blendMode(blendMode)
        .padding(DeckTheme.cardPadding)
        .allowsHitTesting(false)
        .frame(
            width: DeckTheme.cardSize.width,
            height: DeckTheme.cardSize.height
        )
        .background(color)
        .cornerRadius(DeckTheme.cornerRadius)
    }
}

enum CardDragGestureProgress {
    case inactive
    case started
    case changed
}

struct CardStack: View {
    var deck: [CardModel]
    var current: Int
    
    var onSwipeRight: (CardModel) -> Void
    var onSwipeLeft: (CardModel) -> Void
    var onSwipeStart: () -> Void
    var onSwipeAbandoned: () -> Void
    var onCardTapped: (CardModel) -> Void
        
    // Use a dictionary of offsets so that we can animate two cards
    // at once during the transition between.
    // This dictionary is cleared by the gesture lifecycle
    @State var offsets: [CardModel:CGSize] = [:]
    @GestureState private var gestureState: CardDragGestureProgress = .inactive
    @Environment(\.colorScheme) var colorScheme
    
    func indexOf(card: CardModel) -> Int? {
        return deck.firstIndex(where: { $0.id == card.id })
    }
    
    func offset(`for`: CardModel) -> CGSize {
        offsets[`for`] ?? CGSize.zero
    }
    
    func offset(for index: Int) -> CGSize {
        if index < 0 || index >= deck.count {
            return CGSize.zero
        }
        
        return offset(for: deck[index])
    }
    
    private static let THRESHOLD = 128.0
    
    var swipeProgress: CGFloat {
        return (offset(for: current).width / Self.THRESHOLD).clamp(min: -1.0, max: 1.0)
    }
    
    func rotation(for index: Int) -> Double {
        let t = max(0, CGFloat(index - current)) / 16.0 + (swipeProgress) / 64.0
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
                let deck = Array(deck.enumerated().reversed())
                ForEach(deck, id: \.element.id) { index, card in
                        if (index >= current - 1 && index < current + 5) {
                        VStack {
                            let t = max(0, CGFloat(index - current)) / 16.0 - abs(swipeProgress) / 64.0
                            CardView(entry: card)
                                .overlay(RoundedRectangle(cornerSize: CGSize(width: 32, height: 32), style: .continuous)
                                    .fill(colorScheme == .dark ? DeckTheme.darkFog : DeckTheme.lightFog)
                                    .opacity(4.0*t) )
                                .scaleEffect(max(0,min(1, 1-t + 0.03)))
//                                .blur(radius: (0.33-swipeProgress*t)*5*max(0,min(1, 10*t + 0.03)))
                                .rotation3DEffect(
                                    .degrees(-swipeProgress * 100.0 * (0.1-t)), axis: (offset(for: card).height / 100.0, 1, 0), perspective: 0.5)
                                .offset(x: offset(for: card).width, y: offset(for: card).height / 4.0)
                                .rotationEffect(
                                    index != current
                                    ? .degrees(rotation(for: index))
                                    : .degrees(Double(offset(for: card).width / 32.0))
                                )
                                
                                .gesture(TapGesture().onEnded({ onCardTapped(card) }))
                                .gesture(DragGesture()
                                    .updating(
                                        $gestureState,
                                        body: { (value, state, transaction) in
                                            switch state {
                                            case .inactive:
                                                state = .started
                                                onSwipeStart()
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
                                                onSwipeAbandoned()
                                            }
                                        }
                                    })
                                .zIndex(offset(for: card).width == 0 ? 0 : 1) // Bring card to front during drag
                                .disabled(index != current)
                                .opacity(index >= current ? 1 : 0)
                                .shadow(color: Color(red: 0.45, green: 0.25, blue: 0.75).opacity(0.25 * (1.0 - 5.0*t)), radius: 4, x: 0, y: 2)
                                .animation(.spring(duration: 0.2), value: current)
                                
                        }
                    }
                }
            }
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
            deck: [
                CardModel(entry: EntryStub.dummyData(), user: UserProfile.dummyData(), backlinks: []),
                CardModel(entry: EntryStub.dummyData(), user: UserProfile.dummyData(), backlinks: []),
                CardModel(entry: EntryStub.dummyData(), user: UserProfile.dummyData(), backlinks: []),
                CardModel(entry: EntryStub.dummyData(), user: UserProfile.dummyData(), backlinks: []),
                CardModel(entry: EntryStub.dummyData(), user: UserProfile.dummyData(), backlinks: []),
            ],
            current: 0,
            onSwipeRight: { _ in },
            onSwipeLeft: { _ in },
            onSwipeStart: { },
            onSwipeAbandoned: { },
            onCardTapped: { _ in }
        )
    }
}
