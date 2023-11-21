//
//  DeckView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 7/11/2023.
//

import os
import SwiftUI
import ObservableStore
import Combine

enum DeckTheme {}

extension DeckTheme {
    static let reboundSpring = Animation.spring(duration: 0.4, bounce: 0.5)
    
    static let cardPadding = AppTheme.unit * 5
    static let cornerRadius: CGFloat = 32.0
    static let cardSize = CGSize(width: 374, height: 420)
    
    static let cardShadow = Color(red: 0.45, green: 0.25, blue: 0.75)
    
    static let lightFog = Color(red: 0.93, green: 0.81, blue: 0.92)
    
    static let lightBg = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.87, green: 0.86, blue: 0.92), location: 0.00),
            Gradient.Stop(color: lightFog, location: 0.38),
            Gradient.Stop(color: Color(red: 0.92, green: 0.92, blue: 0.85), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.9),
        endPoint: UnitPoint(x: 0.5, y: 0)
    )
    
    static let darkFog = Color(red: 0.2, green: 0.14, blue: 0.26)
    
    static let darkBg = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.13, green: 0.14, blue: 0.2), location: 0.00),
            Gradient.Stop(color: darkFog, location: 0.44),
            Gradient.Stop(color: Color(red: 0.1, green: 0.04, blue: 0.11), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    
    static let lightCardColors: [Color] = [
        Color(red: 0.97, green: 0.49, blue: 0.75),
        Color(red: 0.56, green: 0.62, blue: 0.93),
        Color(red: 0.93, green: 0.59, blue: 0.56),
        Color(red: 0.74, green: 0.52, blue: 0.95),
        Color(red: 0.97, green: 0.75, blue: 0.48)
    ]
    
    static let darkCardColors: [Color] = [
        Color(red: 0.64, green: 0.35, blue: 0.93),
        Color(red: 0.91, green: 0.37, blue: 0.35),
        Color(red: 0.72, green: 0.37, blue: 0.84),
        Color(red: 0.97, green: 0.43, blue: 0.72),
        Color(red: 0.9, green: 0.62, blue: 0.28)
    ]
}

struct DeckView: View {
    @ObservedObject var app: Store<AppModel>
    @StateObject var store: Store<DeckModel> = Store(
        state: DeckModel(),
        environment: AppEnvironment.default
    )
    
    var body: some View {
        ZStack {
            DeckNavigationView(app: app, store: store)
                .zIndex(1)
            
            if store.state.isSearchPresented {
                SearchView(
                    store: store.viewStore(
                        get: \.search,
                        tag: DeckSearchCursor.tag
                    )
                )
                .zIndex(3)
                .transition(SearchView.presentTransition)
            }
            PinTrailingBottom(
                content: FABView(
                    action: {
                        store.send(.setSearchPresented(true))
                    }
                )
                .padding()
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .zIndex(2)
            VStack {
                Spacer()
                ToastStackView(
                    store: app.viewStore(
                        get: \.toastStack,
                        tag: ToastStackCursor.tag
                    )
                )
            }
            .padding()
            .zIndex(3)
        }
        .onAppear {
            store.send(.appear)
        }
        .frame(maxWidth: .infinity)
        /// Replay some app actions on feed store
        .onReceive(
            app.actions.compactMap(DeckAction.from),
            perform: store.send
        )
        /// Replay some feed actions on app store
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
        .onReceive(store.actions) { action in
            DeckAction.logger.debug("\(String(describing: action))")
        }
    }
}

// MARK: Actions
enum DeckAction: Hashable {
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DeckAction"
    )
    
    case detailStack(DetailStackAction)
    
    case setSearchPresented(Bool)
    case activatedSuggestion(Suggestion)
    case search(SearchAction)
    
    case appear
    case setDeck([CardModel])
    case chooseCard(CardModel)
    case cardPickedUp
    case cardReleased
    case cardTapped(CardModel)
    case skipCard(CardModel)
    case appendCards([CardModel])
    case shuffleCardsUpNext([CardModel])
    case topupDeck
    case noCardsToDraw
    
    case nextCard
    case cardPresented(CardModel)
}

extension AppAction {
    static func from(_ action: DeckAction) -> Self? {
        switch action {
        default:
            return nil
        }
    }
}

extension DeckAction {
    static func from(_ action: AppAction) -> Self? {
        switch action {
        default:
            return nil
        }
    }
}

typealias DeckEnvironment = AppEnvironment

enum CardType: Equatable, Hashable {
    case entry(entry: EntryStub, author: UserProfile, backlinks: [EntryStub])
    case action(String)
}

struct CardModel: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var card: CardType
}

extension CardModel {
    init(entry: EntryStub, user: UserProfile, backlinks: [EntryStub]) {
        self.init(card: .entry(entry: entry, author: user, backlinks: backlinks))
    }
}

struct DeckSearchCursor: CursorProtocol {
    typealias Model = DeckModel
    typealias ViewModel = SearchModel

    static func get(state: Model) -> ViewModel {
        state.search
    }

    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.search = inner
        return model
    }

    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .activatedSuggestion(let suggestion):
            return .activatedSuggestion(suggestion)
        case .requestPresent(let isPresented):
            return .setSearchPresented(isPresented)
        default:
            return .search(action)
        }
    }
}

struct DeckDetailStackCursor: CursorProtocol {
    typealias Model = DeckModel
    typealias ViewModel = DetailStackModel

    static func get(state: Model) -> ViewModel {
        state.detailStack
    }

    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.detailStack = inner
        return model
    }

    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
//        case let .requestDeleteMemo(slashlink):
//            return .requestDeleteMemo(slashlink)
//        case let .succeedMergeEntry(parent: parent, child: child):
//            return .succeedMergeEntry(parent: parent, child: child)
//        case let .succeedMoveEntry(from: from, to: to):
//            return .succeedMoveEntry(from: from, to: to)
//        case let .succeedUpdateAudience(receipt):
//            return .succeedUpdateAudience(receipt)
//        case let .succeedSaveEntry(address: address, modified: modified):
//            return .succeedSaveEntry(slug: address, modified: modified)
        case _:
            return .detailStack(action)
        }
    }
}

// MARK: Model
struct DeckModel: ModelProtocol {
    typealias Action = DeckAction
    typealias Environment = DeckEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DeckModel"
    )
    
    var deck: [CardModel] = []
    var seen: [EntryStub] = []
    
    var detailStack = DetailStackModel()
    /// Search HUD
    var isSearchPresented = false
    /// Search HUD
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
    var pointer: Int = 0
    var author: UserProfile? = nil
    var selectionFeedback = UISelectionFeedbackGenerator()
    var feedback = UIImpactFeedbackGenerator()
    
    static func insertAtRandomIndex<T>(item: T, into array: inout [T], skippingFirst skipCount: Int) {
        // Calculate the starting index for the random range
        let startIndex = array.count < skipCount ? 0 : skipCount
        // Ensure the end index is at least equal to the start index
        let endIndex = max(startIndex, array.count)
        
        if (startIndex == endIndex) {
            array.append(item)
            return
        }
        
        // Generate a random index within the range
        let randomIndex = Int.random(in: startIndex..<endIndex)
        
        array.insert(item, at: randomIndex)
    }
    
    var topCard: CardModel? {
        if pointer < 0 || pointer >= deck.count {
            return nil
        }
        
        return deck[pointer]
    }
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch (action) {
        case .detailStack(let action):
            return DeckDetailStackCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .search(let action):
            return DeckSearchCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case let .setSearchPresented(presented):
            var model = state
            model.isSearchPresented = presented
            return Update(state: model)
        case let .activatedSuggestion(suggestion):
            return DeckDetailStackCursor.update(
                state: state,
                action: DetailStackAction.fromSuggestion(suggestion),
                environment: environment
            )
        case .appear:
            let fx: Fx<DeckAction> = Future.detached {
                var results: [EntryStub] = []
                let us = try await environment.noosphere.identity()
                
                var max = 2
                for _ in 0..<25 {
                    guard max > 0 else {
                        break
                    }
                    
                    guard let entry = environment.database.readRandomEntry(owner: us) else {
                        continue
                    }
                    
                    guard !isTooShort(card: entry) else {
                        continue
                    }
                    
                    max -= 1
                    results.append(entry)
                }
                
                let recent = try environment.database.listFeed(owner: us)
                var draw = Array(recent.filter {
                    entry in !isTooShort(card: entry)
                }
                .prefix(10)
                .shuffled()
                .prefix(3))
                
                draw.append(contentsOf: results)
                draw.shuffle()
                
                var deck: [CardModel] = []
                for entry in draw {
                    let user = try await environment.userProfile.identifyUser(
                        did: entry.did,
                        address: entry.address,
                        context: nil
                    )
                    let backlinks = try environment.database.readEntryBacklinks(
                        owner: us,
                        did: entry.did,
                        slug: entry.address.slug
                    )
                    deck.append(CardModel(entry: entry, user: user, backlinks: backlinks))
                }
                
                return .setDeck(deck)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case .topupDeck:
            let fx: Fx<DeckAction> = Future.detached {
                var results: [EntryStub] = []
                let us = try await environment.noosphere.identity()
                var max = 1
                for _ in 0..<25 {
                    guard max > 0 else {
                        break
                    }
                    
                    guard let entry = environment.database.readRandomFreshEntryForCard(owner: us, seen: state.seen.map { entry in entry.address }) else {
                        break
                    }
                    
                    max -= 1
                    results.append(entry)
                }
                
                var deck: [CardModel] = []
                for entry in results {
                    let user = try await environment.userProfile.identifyUser(
                        did: entry.did,
                        address: entry.address,
                        context: nil
                    )
                    let backlinks = try environment.database.readEntryBacklinks(
                        owner: us,
                        did: entry.did,
                        slug: entry.address.slug
                    )
                    deck.append(CardModel(entry: entry, user: user, backlinks: backlinks))
                }
                
                return .appendCards(deck)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case let .setDeck(deck):
            var model = state
            model.deck = deck
            model.seen = deck.compactMap { card in
                switch card.card {
                case let .entry(entry, author, backlinks):
                    return entry
                default:
                    return nil
                }
            }
            model.pointer = 0
            
            if let topCard = deck.first {
                return update(
                    state: model,
                    action: .cardPresented(topCard),
                    environment: environment
                )
                .animation(.spring())
            }
            
            return Update(state: model)
        case .cardPickedUp:
            state.feedback.prepare()
            state.selectionFeedback.prepare()
            state.selectionFeedback.selectionChanged()
            return Update(state: state)
        case .cardReleased:
            state.selectionFeedback.prepare()
            state.selectionFeedback.selectionChanged()
            return Update(state: state)
        case let .cardTapped(card):
            state.feedback.prepare()
            state.feedback.impactOccurred()
            switch card.card {
            case let .entry(entry, author, backlinks):
                return update(
                    state: state,
                    action: .detailStack(
                        .pushDetail(
                            MemoDetailDescription.from(
                                address: entry.address,
                                fallback: entry.excerpt.description
                            )
                        )
                    ),
                    environment: environment
                )
            case _:
                return Update(state: state)
            }
            
        case let .chooseCard(card):
            state.feedback.impactOccurred()
            
            switch card.card {
            case let .entry(entry, author, backlinks):
                let fx: Fx<DeckAction> = Future.detached {
                    let us = try await environment.noosphere.identity()
                    var backlinks = try environment.database
                        .readEntryBacklinks(owner: us, did: entry.did, slug: entry.address.slug)
                        .filter({ backlink in !isSeen(card: backlink) && !isTooShort(card: backlink) })
                    backlinks.shuffle()
                    
                    if backlinks.count == 0 {
                        return .topupDeck
                    }
                    
                    var draw: [CardModel] = []
                    for entry in backlinks.prefix(1) {
                        let user = try await environment.userProfile.identifyUser(
                            did: entry.did,
                            address: entry.address,
                            context: nil
                        )
                        let backlinks = try environment.database.readEntryBacklinks(
                            owner: us,
                            did: entry.did,
                            slug: entry.address.slug
                        )
                        draw.append(CardModel(entry: entry, user: user, backlinks: backlinks))
                    }
                    
                    return .shuffleCardsUpNext(draw)
                }
                .recover({ error in
                    return .noCardsToDraw
                })
                .eraseToAnyPublisher()
                
                return update(
                    state: state,
                    action: .nextCard,
                    environment: environment
                ).mergeFx(fx)
            case .action(let msg):
                logger.log("Action: \(msg)")
                return update(
                    state: state,
                    action: .nextCard,
                    environment: environment
                )
            }
            
        case .skipCard:
            var model = state
            model.pointer += 1
            state.feedback.impactOccurred()
            
            let fx: Fx<DeckAction> = Future.detached {
                var results: [EntryStub] = []
                let us = try await environment.noosphere.identity()
                var max = 1
                for _ in 0..<25 {
                    guard max > 0 else {
                        break
                    }
                    
                    guard let entry = environment.database.readRandomFreshEntryForCard(owner: us, seen: model.seen.map { entry in entry.address }) else {
                        break
                    }
                    
                    max -= 1
                    results.append(entry)
                }
                
                var draw: [CardModel] = []
                for entry in results {
                    let user = try await environment.userProfile.identifyUser(
                        did: entry.did,
                        address: entry.address,
                        context: nil
                    )
                    let backlinks = try environment.database.readEntryBacklinks(
                        owner: us,
                        did: entry.did,
                        slug: entry.address.slug
                    )
                    draw.append(CardModel(entry: entry, user: user, backlinks: backlinks))
                }
                
                return .appendCards(draw)
            }
            .recover({ error in .appendCards([]) })
            .eraseToAnyPublisher()
            
            return Update(state: model, fx: fx)
        case let .shuffleCardsUpNext(entries):
            var model = state
            for entry in entries.filter({ entry in !inDeck(card: entry) }) {
                
                // insert entry into deck at random index (not the first 2 spots)
                Self.insertAtRandomIndex(item: entry, into: &model.deck, skippingFirst: state.pointer + 1)
                
                switch entry.card {
                case let .entry(entry, _, _):
                    model.seen.append(entry)
                    break
                default:
                    break
                }
            }
            
            return Update(state: model)
        case let .appendCards(entries):
            var model = state
            for entry in entries.filter({ entry in !inDeck(card: entry) }) {
                model.deck.append(entry)
                
                switch entry.card {
                case let .entry(entry, _, _):
                    model.seen.append(entry)
                    break
                default:
                    break
                }
            }
            
            return Update(state: model)
        case .noCardsToDraw:
            logger.log("No cards to draw")
            return Update(state: state)
        case .nextCard:
            var model = state
            model.pointer += 1
            
            if let topCard = model.topCard {
                return update(
                    state: model,
                    action: .cardPresented( topCard ),
                    environment: environment
                )
            }
            
            return Update(state: model)
        case .cardPresented(let card):
            logger.log("Card presented \(card.id)")
            return Update(state: state)
        }
        
        func isTooShort(card: EntryStub) -> Bool {
            return card.excerpt.base.count < 64
        }
        
        func isSeen(card: EntryStub) -> Bool {
            return state.seen.contains(where: { entry in entry == card })
        }
        
        func inDeck(card: CardModel) -> Bool {
            return state.deck.contains(where: { entry in entry == card })
        }
    }
}
