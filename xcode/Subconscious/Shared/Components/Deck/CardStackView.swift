import SwiftUI

struct CardContentView: View {
    @Environment (\.colorScheme) var colorScheme
    var entry: EntryStub
    var backlinks: [EntryStub]
    var onLink: (EntryLink) -> Void
    
    var highlight: Color {
        entry.highlightColor(colorScheme: colorScheme)
    }
    
    
    var body: some View {
        SubtextView(
            peer: entry.toPeer(),
            subtext: entry.excerpt,
            onLink: onLink
        )
        // Opacity allows blendMode to show through
        .foregroundStyle(.primary.opacity(0.8))
        .accentColor(highlight)
        .padding(DeckTheme.cardPadding)
        
        Spacer()
        
        HStack {
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
        .foregroundStyle(highlight)
        .padding(DeckTheme.cardPadding)
    }
}

struct CardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var entry: CardModel
    var onLink: (EntryLink) -> Void
    
    var color: Color {
        switch entry.card {
        case let .entry(entry, _, _):
            return entry.color(colorScheme: colorScheme)
        case let .prompt(_, entry, _, _):
            return entry.color(colorScheme: colorScheme)
        default:
            return .secondary
        }
    }
    
    var highlight: Color {
        switch entry.card {
        case let .entry(entry, _, _):
            return entry.highlightColor(colorScheme: colorScheme)
        case let .prompt(_, entry, _, _):
            return entry.highlightColor(colorScheme: colorScheme)
        default:
            return .secondary
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
                CardContentView(
                    entry: entry,
                    backlinks: backlinks,
                    onLink: onLink
                )
            case let .prompt(message, entry, _, backlinks):
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "sparkles")
                        
                        Text(message)
                    }
                    .padding(DeckTheme.cardPadding)
                    .foregroundStyle(highlight)
                    .font(.subheadline)
                    
                    Divider()
                        .overlay(highlight)
                    
                    CardContentView(
                        entry: entry,
                        backlinks: backlinks,
                        onLink: onLink
                    )
                }
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
                        ? DeckTheme.darkBgMid
                        : DeckTheme.lightBgMid
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
                    0.2 * (1.0 - 5.0*stackFactor)
                ),
                radius: 2.5,
                x: 0,
                y: 1.5
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
    var color: Color
    
    var body: some View {
        Rectangle()
            .frame(
                width: DeckTheme.dragTargetSize.width,
                height: DeckTheme.dragTargetSize.height
            )
            .foregroundStyle(color)
            .blur(radius: 16)
    }
}

struct CardStack: View {
    private static let swipeActivationThreshold = 128.0
    private static let swipeThrowDistance = 512.0
    
    var deck: [CardModel]
    var current: Int
    
    var onSwipeRight: (CardModel) -> Void
    var onSwipeLeft: (CardModel) -> Void
    var onSwipeStart: () -> Void
    var onSwipeAbandoned: () -> Void
    var onCardTapped: (CardModel) -> Void
    var onLink: (EntryLink) -> Void
        
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
            CardView(
                entry: card,
                onLink: onLink
            )
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
        .transition(
            .asymmetric(
                insertion: .scale.combined(
                    with: .push(
                        from: .bottom
                    )
                    .combined(with: .offset(y: -300))
                ),
                removal: .scale
            )
        )
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
            CardSwipeGlowEffect(color: Color.brandMarkCyan)
                .offset(x: 200, y: 0)
                .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
                .opacity(swipeProgress)
        )
        .overlay(
            CardSwipeGlowEffect(color: Color.brandMarkRed)
                .offset(x: -200, y: 0)
                .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
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
            onCardTapped: { _ in },
            onLink: { _ in }
        )
    }
}
