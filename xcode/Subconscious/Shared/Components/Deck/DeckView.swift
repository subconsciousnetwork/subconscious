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

struct DeckView: View {
    @ObservedObject var app: Store<AppModel>
    @StateObject var store: Store<DeckModel> = Store(
        state: DeckModel(),
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: Logger(
            subsystem: Config.default.rdns,
            category: "DeckStore"
        )
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
                ToastStackView(
                    store: app.viewStore(
                        get: \.toastStack,
                        tag: ToastStackCursor.tag
                    )
                )
                Spacer()
            }
            .zIndex(3)
        }
        .onAppear {
            store.send(.appear)
        }
        .frame(maxWidth: .infinity)
        /// Replay some app actions on deck store
        .onReceive(
            app.actions.compactMap(DeckAction.from),
            perform: store.send
        )
        /// Replay some deck actions on app store
        .onReceive(
            store.actions.compactMap(AppAction.from),
            perform: app.send
        )
    }
}

// MARK: Actions
enum DeckAction: Hashable {
    case requestDeckRoot
    case detailStack(DetailStackAction)
    
    case setSearchPresented(Bool)
    case activatedSuggestion(Suggestion)
    case search(SearchAction)
    
    case appear
    case setDeck([CardModel])
    
    case cardPickedUp
    case cardReleased
    case cardTapped(CardModel)
    
    case chooseCard(CardModel)
    case skipCard(CardModel)
    
    case appendCards([CardModel])
    case shuffleCardsUpNext([CardModel])
    
    case topupDeck
    case noCardsToDraw
    
    case nextCard
    case cardPresented(CardModel)
    
    case refreshDeck
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
        case .requestDeckRoot:
            return .requestDeckRoot
        default:
            return nil
        }
    }
}

typealias DeckEnvironment = AppEnvironment

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
        case _:
            return .detailStack(action)
        }
    }
}

// MARK: Model
struct DeckModel: ModelProtocol {
    public static let backlinksToDraw = 1
    
    typealias Action = DeckAction
    typealias Environment = DeckEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DeckModel"
    )
    
    var detailStack = DetailStackModel()
    
    /// Search HUD
    var isSearchPresented = false
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
    var deck: Array<CardModel> = []
    
    // The set of cards to avoid drawing again, if possible
    var seen: Set<EntryStub> = []
    var pointer: Int = 0
    var author: UserProfile? = nil
    var selectionFeedback = UISelectionFeedbackGenerator()
    var feedback = UIImpactFeedbackGenerator()
    
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
            return appear(state: state, environment: environment)
        case .refreshDeck:
            return refreshDeck(state: state, environment: environment)
        case .topupDeck:
            return topupDeck(state: state, environment: environment)
        case let .setDeck(deck):
            return setDeck(state: state, deck: deck, environment: environment)
        case .cardPickedUp:
            return cardPickedUp(state: state)
        case .cardReleased:
            return cardReleased(state: state)
        case let .cardTapped(card):
            return cardTapped(state: state, card: card, environment: environment)
        case let .chooseCard(card):
            return chooseCard(state: state, card: card, environment: environment)
        case .skipCard:
            return skipCard(state: state, environment: environment)
        case let .shuffleCardsUpNext(entries):
            return shuffleCardsUpNext(state: state, entries: entries)
        case let .appendCards(entries):
            return appendCards(state: state, entries: entries)
        case .noCardsToDraw:
            return noCardsToDraw(state: state)
        case .nextCard:
            return nextCard(state: state, environment: environment)
        case let .cardPresented(card):
            return cardPresented(state: state, card: card)
        case .requestDeckRoot:
            return requestDeckRoot(
                state: state,
                environment: environment
            )
        }
        
        func appear(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            if state.deck.isEmpty {
                return update(
                    state: state,
                    action: .refreshDeck,
                    environment: environment
                )
            }
            
            return Update(state: state)
        }
        
        func refreshDeck(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            let fx: Fx<DeckAction> = Future.detached {
                let us = try await environment.noosphere.identity()
                let recent = try environment.database.listFeed(owner: us)
                
                var initialDraw = Array(recent
                    .prefix(10) // take the 10 most recent posts
                    .shuffled() // shuffle
                    .prefix(3)) // take 3
                
                // Draw 2 random cards to keep it surprising
                for _ in 0..<2 {
                    guard let entry = environment.database.readRandomEntry(owner: us) else {
                        continue
                    }
                    
                    initialDraw.append(entry)
                }
                
                initialDraw.shuffle()
                
                var deck: [CardModel] = []
                for entry in initialDraw {
                    let card = try await toCard(
                        entry: entry,
                        ourIdentity: us,
                        environment: environment
                    )
                    
                    deck.append(card)
                }
                
                return .setDeck(deck)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return update(
                state: state,
                action: .setDeck([]),
                environment: environment
            ).mergeFx(fx)
        }
        
        func topupDeck(state: Self, environment: Environment) -> Update<Self> {
            let fx: Fx<DeckAction> = Future.detached {
                let us = try await environment.noosphere.identity()
                // We're in a fallback case where we failed to find a card
                // so just draw ANYTHING
                guard let entry = environment.database.readRandomEntry(owner: us) else {
                    return .noCardsToDraw
                }
                
                let card = try await toCard(
                    entry: entry,
                    ourIdentity: us,
                    environment: environment
                )
                
                return .appendCards([card])
            }
            .recover({ error in .noCardsToDraw })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        }

        func setDeck(state: Self, deck: [CardModel], environment: Environment) -> Update<Self> {
            var model = state
            model.deck = deck
            model.seen = Set(deck.compactMap { card in card.entry })
            model.pointer = 0
            
            if let topCard = deck.first {
                return update(
                    state: model,
                    action: .cardPresented(topCard),
                    environment: environment
                )
                .animation(.spring(
                    response: 0.5,
                    dampingFraction: 0.8,
                    blendDuration: 0
                ))
            }
            
            return Update(state: model)
        }

        func cardPickedUp(state: Self) -> Update<Self> {
            state.feedback.prepare()
            state.selectionFeedback.prepare()
            state.selectionFeedback.selectionChanged()
            
            return Update(state: state)
        }

        func cardReleased(state: Self) -> Update<Self> {
            state.feedback.prepare()
            state.selectionFeedback.prepare()
            state.selectionFeedback.selectionChanged()
            
            return Update(state: state)
        }

        func cardTapped(state: Self, card: CardModel, environment: Environment) -> Update<Self> {
            state.feedback.prepare()
            state.feedback.impactOccurred()
            
            if let entry = card.entry {
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
            }
            
            return Update(state: state)
        }
        
        func shuffleInBacklinks(_ backlinks: [EntryStub]) -> Update<Self> {
            let fx: Fx<DeckAction> = Future.detached {
                let us = try await environment.noosphere.identity()
                
                // Filter to valid backlinks
                let backlinks = backlinks
                    .filter({ backlink in !isSeen(entry: backlink) })
                    .shuffled()
                
                if backlinks.count == 0 {
                    return .topupDeck
                }
                
                var draw: [CardModel] = []
                for entry in backlinks.prefix(backlinksToDraw) {
                    let card = try await toCard(
                        entry: entry,
                        ourIdentity: us,
                        environment: environment
                    )
                    
                    draw.append(card)
                }
                
                return .shuffleCardsUpNext(draw)
            }
            .recover({ error in
                return .topupDeck
            })
            .eraseToAnyPublisher()
            
            return update(
                state: state,
                action: .nextCard,
                environment: environment
            ).mergeFx(fx)
        }

        func chooseCard(state: Self, card: CardModel, environment: Environment) -> Update<Self> {
            state.feedback.impactOccurred()
            
            switch card.card {
            case let .entry(_, _, backlinks):
               return shuffleInBacklinks(backlinks)
            case let .prompt(_, _, _, backlinks):
               return shuffleInBacklinks(backlinks)
            case .action(let msg):
                logger.log("Action: \(msg)")
                return update(
                    state: state,
                    action: .nextCard,
                    environment: environment
                )
            }
        }

        func skipCard(state: Self, environment: Environment) -> Update<Self> {
            state.feedback.impactOccurred()
            
            let fx: Fx<DeckAction> = Future.detached {
                let us = try await environment.noosphere.identity()
                
                guard let entry = environment.database.readRandomUnseenEntry(
                    owner: us,
                    seen: state.seen.map { entry in entry.address }
                ) else {
                    return .topupDeck
                }
                
                var draw: [CardModel] = []
                let card = try await toCard(
                    entry: entry,
                    ourIdentity: us,
                    environment: environment
                )
                    
                draw.append(card)
                
                return .appendCards(draw)
            }
            .recover({ error in .topupDeck })
            .eraseToAnyPublisher()
            
            return update(
                state: state,
                action: .nextCard,
                environment: environment
            ).mergeFx(fx)
        }

        func shuffleCardsUpNext(state: Self, entries: [CardModel]) -> Update<Self> {
            var model = state
            for entry in entries {
                // insert entry into deck at random past our pointer (not the first 2 spots)
                model.deck.insertAtRandomIndex(
                    entry,
                    skippingFirst: state.pointer + 1
                )
                
                switch entry.card {
                case let .entry(entry, _, _):
                    model.seen.insert(entry)
                    break
                default:
                    break
                }
            }
            
            return Update(state: model)
        }

        func appendCards(state: Self, entries: [CardModel]) -> Update<Self> {
            var model = state
            for entry in entries {
                model.deck.append(entry)
                
                switch entry.card {
                case let .entry(entry, _, _):
                    model.seen.insert(entry)
                    break
                default:
                    break
                }
            }
            
            return Update(state: model)
        }
        
        func requestDeckRoot(
            state: Self,
            environment: AppEnvironment
        ) -> Update<Self> {
            return DeckDetailStackCursor.update(
                state: state,
                action: .setDetails([]),
                environment: environment
            )
        }

        func noCardsToDraw(state: Self) -> Update<Self> {
            logger.log("No cards to draw")
            return Update(state: state)
        }

        func nextCard(state: Self, environment: Environment) -> Update<Self> {
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
        }

        func cardPresented(state: Self, card: CardModel) -> Update<Self> {
            logger.log("Card presented \(card.id)")
            return Update(state: state)
        }

        
        func toCard(
            entry: EntryStub,
            ourIdentity: Did,
            environment: DeckEnvironment
        ) async throws -> CardModel {
            // TODO: also list the slashlinks in the body of the card as possible connections
            // these aren't "backlinks" so we should expand the name to "related"
            let backlinks = try environment.database.readEntryBacklinks(
                owner: ourIdentity,
                did: entry.did,
                slug: entry.address.slug
            )
           
            let user = try await environment.userProfile.identifyUser(
                did: entry.did,
                address: entry.address,
                context: nil
            )
            
            return CardModel(
                card: .prompt(
                    message: Prompt.connect.randomElement()!.message,
                    entry: entry,
                    author: user,
                    backlinks: backlinks
                )
            )
        }
        
        func isTooShort(entry: EntryStub) -> Bool {
            return entry.excerpt.base.count < 64
        }
        
        func isSeen(entry: EntryStub) -> Bool {
            return state.seen.contains(where: { entry in entry == entry })
        }
        
        func inDeck(entry: CardModel) -> Bool {
            return state.deck.contains(where: { entry in entry == entry })
        }
    }
}
