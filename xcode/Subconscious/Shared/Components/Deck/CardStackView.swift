import SwiftUI

extension Hashable {
    private func colors(colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark
            ? DeckTheme.darkCardColors
            : DeckTheme.lightCardColors
    }
    
    func color(colorScheme: ColorScheme) -> Color {
        let colors = colors(colorScheme: colorScheme)
        return colors[abs(self.hashValue) % colors.count]
    }
}

struct CardView: View {
    var entry: CardModel
    @Environment(\.colorScheme) var colorScheme
    
    var color: Color {
        switch entry.card {
        case let .entry(entry, _, _):
            return entry.color(colorScheme: colorScheme)
        default:
            return entry.card.color(colorScheme: colorScheme)
        }
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
    case active
}

struct CardEffectModifier: ViewModifier {
    var stackFactor: CGFloat
    var swipeProgress: CGFloat
    var offset: CGSize
    var focused: Bool
    var colorScheme: ColorScheme
    
    func rotation(_ stackFactor: CGFloat) -> Double {
        let fundamental = 6.0*Double(sin(CGFloat(stackFactor - 0.1) * 40))
        let harmonic = 2.0*Double(sin((stackFactor - 0.45) * 10))
        
        let result = (fundamental + harmonic)
        
        return result + (stackFactor * swipeProgress * 5)
    }
    
    func body(content: Content) -> some View {
        content
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
                axis: (offset.height / 100.0, 1, 0),
                perspective: 0.5
            )
            .offset(
                // Move with the swipe
                x: offset.width,
                // Slightly follow the swipe
                y: offset.height / 4.0
            )
            .rotationEffect(
                focused
                // Foreground card rotates based on gesture
                ? .degrees(Double(offset.width / 32.0))
                // Background cards rotate for decoration
                : .degrees(rotation(stackFactor))
            )
            // Prevent any gestures on background cards
            .disabled(!focused)
            // Reduce shadow intensity with depth
            .shadow(
                color: DeckTheme.cardShadow.opacity(
                    0.25 * (1.0 - 5.0*stackFactor)
                ),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

struct CardGestureModifier: ViewModifier {
    @Binding var offsets: [CardModel:CGSize]
    @GestureState private var gestureState: CardDragGestureProgress = .inactive
    
    var onTapped: () -> Void
    var onSwipeStart: () -> Void
    var onSwipeChanged: (CGSize) -> Void
    var onSwipeComplete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                TapGesture().onEnded { _ in onTapped() }
            )
            .gesture(DragGesture()
                 // For some reason this seems to be the only way
                 // to detect the start of a drag gesture
                .updating(
                    $gestureState,
                    body: { (value, state, transaction) in
                        switch state {
                        case .inactive:
                            state = .started
                            onSwipeStart()
                            break
                        case .started:
                            state = .active
                            break
                        case .active:
                            break
                        }
                    }
                )
                .onChanged { gesture in
                    onSwipeChanged(gesture.translation)
                }
                .onEnded { _ in
                    onSwipeComplete()
                }
            )
    }
}

struct CardSwipeGlowEffect: View {
    var body: some View {
        Rectangle()
            .frame(
                width: DeckTheme.dragTargetSize.width,
                height: DeckTheme.dragTargetSize.height
            )
            .foregroundStyle(Color.brandMarkPink)
            .blur(radius: 16)
    }
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
    @Environment(\.colorScheme) var colorScheme
    
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
    
    private func dragChanged(card: CardModel, translation: CGSize) {
        withAnimation(.interactiveSpring()) {
            // Clear old offsets
            offsets.removeAll()
            // Stick the top card to the gesture
            offsets[card] = translation
        }
    }
    
    private func dragComplete(card: CardModel) {
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
    }
    
    var enumeratedDeck: [EnumeratedSequence<[CardModel]>.Element] {
        Array(deck.enumerated())
    }
    
    func effects(card: CardModel, stackFactor: CGFloat, focused: Bool) -> CardEffectModifier {
        CardEffectModifier(
            stackFactor: stackFactor,
            swipeProgress: swipeProgress,
            offset: offset(
                for: card
            ),
            focused: focused,
            colorScheme: colorScheme
        )
    }
    
    func gestures(card: CardModel) -> CardGestureModifier {
        CardGestureModifier(
            offsets: $offsets,
            onTapped: { onCardTapped(card) },
            onSwipeStart: onSwipeStart,
            onSwipeChanged: { translation in
                dragChanged(card: card, translation: translation)
            },
            onSwipeComplete: {
                dragComplete(card: card)
            }
        )
    }
    
    private func innerCard(size: CGSize, index: Int, card: CardModel) -> some View {
        VStack {
            Spacer()
            
            let stackFactor = stackFactor(for: index)
            CardView(entry: card)
                // Size card based on available space
                .frame(
                    width: size.width,
                    height: size.width * 1.25
                )
                .modifier(
                    effects(
                        card: card,
                        stackFactor: stackFactor,
                        focused: index == current
                    )
                )
                .modifier(
                    gestures(card: card)
                )
                // Fade out cards as we move past them
                .opacity(index >= current ? 1 : 0)
                .animation(.spring(), value: current)
            
            Spacer()
        }
        .zIndex(Double(deck.count - index))
    }
    
    var body: some View {
        VStack {
            Spacer()
            GeometryReader { geo in
                ZStack {
                    ForEach(enumeratedDeck, id: \.element.id) {
                        index, card in
                        if (index >= current - 1 && index < current + 4) {
                            innerCard(size: geo.size, index: index, card: card)
                        }
                    }
                }
            }
        }
        .overlay(
            CardSwipeGlowEffect()
                .offset(x: 200, y: 0)
                .blendMode(.screen)
                .opacity(swipeProgress)
        )
        .overlay(
            CardSwipeGlowEffect()
                .offset(x: -200, y: 0)
                .blendMode(.plusDarker)
                .opacity(swipeProgress)
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
