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
                    // Opacity allows blendMode to show through
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
    private static let swipeActivationThreshold = 128.0
    private static let swipeThrowDistance = 1024.0
    
    var deck: [CardModel]
    var current: Int
    
    var onSwipeRight: (CardModel) -> Void
    var onSwipeLeft: (CardModel) -> Void
    var onSwipeStart: () -> Void
    var onSwipeAbandoned: () -> Void
    var onCardTapped: (CardModel) -> Void
        
    // Use a dictionary of offsets so that we can animate two cards at once during the transition.
    // This dictionary is frequently cleared during the gesture lifecycle.
    @State var offsets: [CardModel:CGSize] = [:]
    @GestureState private var gestureState: CardDragGestureProgress = .inactive
    @Environment(\.colorScheme) var colorScheme
    
//    func indexOf(card: CardModel) -> Int? {
//        return deck.firstIndex(where: { $0.id == card.id })
//    }
    
    func offset(`for`: CardModel) -> CGSize {
        offsets[`for`] ?? CGSize.zero
    }
    
    func offset(for index: Int) -> CGSize {
        if index < 0 || index >= deck.count {
            return CGSize.zero
        }
        
        return offset(for: deck[index])
    }
    
    // Ranges from -1 (skip) to 1 (choose)
    var swipeProgress: CGFloat {
        return (
            offset(
                for: current
            ).width / Self.swipeActivationThreshold
        ).clamp(
            min: -1.0,
            max: 1.0
        )
    }
    
    func stackFactor(for index: Int) -> CGFloat {
        return max(0, CGFloat(index - current)) / 16.0 - abs(swipeProgress) / 64.0
    }
    
    func rotation(for index: Int, stackFactor: CGFloat) -> Double {
        let fundamental = 6.0*Double(sin(CGFloat(stackFactor - 0.1) * 40))
        let harmonic = 2.0*Double(sin((stackFactor - 0.45) * 10))
        
        let result = (fundamental + harmonic)
        
        return result + (stackFactor * swipeProgress * 5)
    }
    
    var body: some View {
        VStack {
            Spacer()
            GeometryReader { geo in
                ZStack {
                    let deck = Array(deck.enumerated())
                    ForEach(deck, id: \.element.id) { index, card in
                        if (index >= current - 1 && index < current + 3) {
                            VStack {
                                Spacer()
                                
                                let stackFactor = stackFactor(for: index)
                                CardView(entry: card)
                                    // Size card based on available space
                                    .frame(
                                        width: geo.size.width,
                                        height: geo.size.width * 1.25
                                    )
                                    // Fade cards out towards a neutral color based on depth
                                    .overlay(
                                        Rectangle()
                                            .fill(
                                                colorScheme == .dark
                                                ? DeckTheme.darkFog
                                                : DeckTheme.lightFog
                                            )
                                            .opacity(4.0*stackFactor)
                                    )
                                    .scaleEffect(max(0,min(1, 1-stackFactor + 0.03)))
                                    .rotation3DEffect(
                                        .degrees(
                                            -swipeProgress * 100.0 * (
                                                0.1-stackFactor
                                            )
                                        ),
                                        // Tilt the card based on the vertical displacement
                                        axis: (offset(for: card).height / 100.0, 1, 0),
                                        perspective: 0.5
                                    )
                                    .offset(
                                        // Move with the swipe
                                        x: offset(for: card).width,
                                        // Slightly follow the swipe
                                        y: offset(for: card).height / 4.0
                                    )
                                    .rotationEffect(
                                        index == current
                                        // Foreground card rotates based on gesture
                                        ? .degrees(Double(offset(for: card).width / 32.0))
                                        // Background cards rotate for decoration
                                        : .degrees(rotation(for: index, stackFactor: stackFactor))
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
                                            withAnimation(DeckTheme.reboundSpring) {
                                                let offset = offset(for: card).width
                                                if abs(offset) > Self.swipeActivationThreshold {
                                                    // Throw the current card offscreen
                                                    offsets[card]?.width =
                                                        offset > 0
                                                            ? Self.swipeThrowDistance
                                                            : -Self.swipeThrowDistance
                                                    
                                                    if (offset > 0) {
                                                        onSwipeRight(card)
                                                    } else {
                                                        onSwipeLeft(card)
                                                    }
                                                } else {
                                                    // Reset the card position
                                                    offsets[card] = CGSize.zero
                                                    onSwipeAbandoned()
                                                }
                                            }
                                        })
                                    // Prevent any gestures on background cards
                                    .disabled(index != current)
                                    // Fade out cards as we move past them
                                    .opacity(index >= current ? 1 : 0)
                                    // Reduce shadow intensity with depth
                                    .shadow(
                                        color: DeckTheme.cardShadow.opacity(
                                            0.25 * (1.0 - 5.0*stackFactor)
                                        ),
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                                    .animation(.spring(duration: 0.2), value: current)
                                
                                Spacer()
                            }
                            .zIndex(Double(deck.count - index))
                            
                        }
                    }
                }
            }
        }
        .overlay(
            Rectangle()
                .frame(
                    width: DeckTheme.dragTargetSize.width,
                    height: DeckTheme.dragTargetSize.height
                )
                .foregroundStyle(Color.brandMarkPink)
                .offset(x: 200, y: 0)
                .blur(radius: 16)
                .blendMode(.screen)
                .opacity(swipeProgress)
        )
        .overlay(
            Rectangle()
                .frame(
                    width: DeckTheme.dragTargetSize.width,
                    height: DeckTheme.dragTargetSize.height
                )
                .foregroundStyle(Color.brandMarkPink)
                .offset(x: -200, y: 0)
                .blur(radius: 16)
                .blendMode(.plusDarker)
                .opacity(-swipeProgress)
        )
    }
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
