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
            app.actions
                .compactMap(DeckAction.from)
                .filter({ _ in app.state.selectedAppTab == .deck }),
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
    case requestDiscardDeck
    case detailStack(DetailStackAction)
    
    case setSearchPresented(Bool)
    case activatedSuggestion(Suggestion)
    case search(SearchAction)
    
    case appear
    case setDeck(_ cards: [CardModel], _ startIndex: Int = 0)
    
    case cardPickedUp
    case cardReleased
    case cardDetailRequested(CardModel)
    
    case chooseCard(CardModel)
    case skipCard(CardModel)
    
    case appendCards([CardModel])
    case prependCards([CardModel])
    case shuffleCardsUpNext([CardModel])
    
    case topupDeck
    case noCardsToDraw
    
    case nextCard
    case cardPresented(CardModel)
    
    case refreshUpcomingCards
    case refreshDeck
    case refreshLikes
    case succeedRefreshLikes([Slashlink])
    case failRefreshLikes(String)
    
    /// Note lifecycle events.
    /// `request`s are passed up to the app root
    /// `succeed`s are passed down from the app root
    case requestDeleteEntry(Slashlink?)
    case succeedDeleteEntry(Slashlink)
    case requestSaveEntry(_ entry: MemoEntry)
    case succeedSaveEntry(_ address: Slashlink, _ modified: Date)
    case requestMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case requestMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case requestUpdateAudience(_ address: Slashlink, _ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)
    case requestAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    case succeedAssignNoteColor(_ address: Slashlink, _ color: ThemeColor)
    case requestAppendToEntry(_ address: Slashlink, _ append: String)
    case succeedAppendToEntry(_ address: Slashlink)
    case requestUpdateLikeStatus(Slashlink, liked: Bool)
    case succeedUpdateLikeStatus(_ address: Slashlink, liked: Bool)
}

extension AppAction {
    static func from(_ action: DeckAction) -> Self? {
        switch action {
        case let .requestDeleteEntry(entry):
            return .deleteEntry(entry)
        case let .requestSaveEntry(entry):
            return .saveEntry(entry)
        case let .requestMoveEntry(from, to):
            return .moveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .mergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .updateAudience(address: address, audience: audience)
        case let .requestAssignNoteColor(address, color):
            return .assignColor(address: address, color: color)
        case let .requestAppendToEntry(address, append):
            return .appendToEntry(address: address, append: append)
        case let .requestUpdateLikeStatus(address, liked):
            return .setLiked(address: address, liked: liked)
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
        case let .succeedSaveEntry(address, modified):
            return .succeedSaveEntry(address, modified)
        case let .succeedDeleteEntry(entry):
            return .succeedDeleteEntry(entry)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        case let .succeedAssignNoteColor(address, color):
            return .succeedAssignNoteColor(address, color)
        case let .succeedAppendToEntry(address):
            return .succeedAppendToEntry(address)
        case let .succeedUpdateLikeStatus(address, liked):
            return .succeedUpdateLikeStatus(address, liked: liked)
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
        case let .requestSaveEntry(entry):
            return .requestSaveEntry(entry)
        case let .requestDeleteEntry(entry):
            return .requestDeleteEntry(entry)
        case let .requestMoveEntry(from, to):
            return .requestMoveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .requestMergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .requestUpdateAudience(address, audience)
        case let .requestAssignNoteColor(address, color):
            return .requestAssignNoteColor(address, color)
        case let .requestAppendToEntry(address, append):
            return .requestAppendToEntry(address, append)
        case let .requestUpdateLikeStatus(address, liked):
            return .requestUpdateLikeStatus(address, liked: liked)
        case _:
            return .detailStack(action)
        }
    }
}

// MARK: Model
struct DeckModel: ModelProtocol {
    public static let backlinksToDraw = 1
    public static let maxRewardCardBufferSize = 4
    
    typealias Action = DeckAction
    typealias Environment = DeckEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DeckModel"
    )
    
    var detailStack = DetailStackModel()
    
    var loadingStatus: LoadingState = .initial
    
    /// Search HUD
    var isSearchPresented = false
    var search = SearchModel(
        placeholder: "Search or create..."
    )
    
    var deck: Array<CardModel> = []
    var buffer: [CardModel] = []
    
    // The set of cards to avoid drawing again, if possible
    var seen: Set<EntryStub> = []
    var pointer: Int = 0
    var author: UserProfile? = nil
    var likes: [Slashlink] = []
    
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
            return appear(
                state: state,
                environment: environment
            )
        case .refreshDeck, .requestDiscardDeck:
            return discardAndRedrawDeck(
                state: state,
                environment: environment
            )
        case .topupDeck:
            return topupDeck(state: state, environment: environment)
        case let .setDeck(deck, startIndex):
            return setDeck(
                state: state,
                environment: environment,
                deck: deck,
                startIndex: startIndex
            )
        case .cardPickedUp:
            return cardPickedUp(state: state)
        case .cardReleased:
            return cardReleased(state: state)
        case let .cardDetailRequested(card):
            return cardDetailRequested(
                state: state,
                card: card,
                environment: environment
            )
        case let .chooseCard(card):
            return chooseCard(
                state: state,
                card: card,
                environment: environment
            )
        case .skipCard:
            return skipCard(state: state, environment: environment)
        case let .shuffleCardsUpNext(entries):
            return shuffleCardsUpNext(
                state: state,
                entries: entries
            )
        case let .prependCards(entries):
            return prependCards(
                state: state,
                entries: entries
            )
        case let .appendCards(entries):
            return appendCards(
                state: state,
                entries: entries
            )
        case .noCardsToDraw:
            return noCardsToDraw(state: state)
        case .nextCard:
            return nextCard(
                state: state,
                environment: environment
            )
        case let .cardPresented(card):
            return cardPresented(state: state, card: card)
        case .requestDeckRoot:
            return requestDeckRoot(
                state: state,
                environment: environment
            )
        case .refreshUpcomingCards:
            return refreshUpcomingCards(
                state: state,
                environment: environment
            )
        case .refreshLikes:
            return refreshLikes(
                state: state,
                environment: environment
            )
        case let .succeedRefreshLikes(likes):
            return succeedRefreshLikes(
                state: state,
                environment: environment,
                likes: likes
            )
        case let .failRefreshLikes(error):
            return failRefreshLikes(
                state: state,
                environment: environment,
                error: error
            )
        case let .succeedSaveEntry(address, modified):
            return update(
                state: state,
                actions: [
                    .detailStack(.succeedSaveEntry(address, modified)),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedDeleteEntry(address):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedDeleteEntry(address)
                    ),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedMoveEntry(from, to):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedMoveEntry(
                            from: from,
                            to: to
                        )
                    ),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedMergeEntry(parent, child):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedMergeEntry(parent: parent, child: child)
                    ),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedUpdateAudience(receipt):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedUpdateAudience(receipt)
                    ),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedAssignNoteColor(address, color):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedAssignNoteColor(address, color)
                    ),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedAppendToEntry(address):
            return update(
                state: state,
                actions: [
                    .detailStack(
                        .succeedAppendToEntry(address)
                    ),
                    .refreshUpcomingCards
                ],
                environment: environment
            )
        case let .succeedUpdateLikeStatus(address, liked):
            return succeedUpdateLikeStatus(
                state: state,
                environment: environment,
                address: address,
                liked: liked
            )
        case .requestDeleteEntry, .requestSaveEntry, .requestMoveEntry,
                .requestMergeEntry, .requestUpdateAudience, .requestAssignNoteColor,
                .requestAppendToEntry, .requestUpdateLikeStatus:
            return Update(state: state)
        }
        
        func appear(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            if state.deck.isEmpty {
                return update(
                    state: state,
                    actions: [.refreshLikes, .refreshDeck],
                    environment: environment
                )
            }
            
            return Update(state: state)
        }
        
        func discardAndRedrawDeck(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            if state.loadingStatus == .loading {
                logger.log("Already refreshing, skip.")
                return Update(state: state)
            }
            
            var model = state
            model.loadingStatus = .loading
            
            let fx: Fx<DeckAction> = Future.detached {
                try? await Task.sleep(for: .seconds(Duration.loading))
                
                let us = try await environment.noosphere.identity()
                let recent = try environment.database.listAll(owner: us, limit: 5)
                let likes = try await environment.userLikes.readOurLikes()
                
                var initialDraw = Array(
                    recent
                        .prefix(5)
                        .shuffled()
                        .prefix(2)
                )
            
                if let entry = environment.database.readRandomEntry(owner: us) {
                    initialDraw.append(entry)
                }
                
                initialDraw.shuffle()
                
                var deck: [CardModel] = []
                for entry in initialDraw {
                    let card = try await toCard(
                        entry: entry,
                        ourIdentity: us,
                        environment: environment,
                        liked: likes.contains(where: { like in like == entry.address })
                    )
                    
                    deck.append(card)
                }
                
                return .setDeck(deck)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return Update(state: model, fx: fx).animation(.easeOutCubic())
        }
        
        func refreshUpcomingCards(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            let deck = state.deck
            
            let fx: Fx<DeckAction> = Future.detached {
                // Create the first slice of the deck (unchanged)
                let firstSlice = deck.prefix(upTo: state.pointer)
                let likes = try await environment.userLikes.readOurLikes()

                // Initialize an array for the updated cards
                var updated: [CardModel] = Array(firstSlice)

                // Update only the second slice of the deck (from state.pointer onwards)
                for card in deck[state.pointer...] {
                    guard let address = card.entry?.address,
                          let did = card.entry?.did else {
                        continue
                    }
                    
                    guard let entry = try environment.database.readEntry(
                        for: Slashlink(
                            peer: .did(did),
                            slug: address.slug
                        )
                    ) else {
                        continue
                    }
                    
                    updated.append(
                        card.update(
                            entry: entry,
                            liked: likes.contains(where: { like in like == entry.address })
                        )
                    )
                }

                // Set the combined deck and return
                return .setDeck(updated, state.pointer)
            }
            .recover({ error in
                .noCardsToDraw
            })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        }
        
        func refreshLikes(
            state: Self,
            environment: Environment
        ) -> Update<Self> {
            let fx: Fx<DeckAction> = Future.detached {
                let likes = try await environment.userLikes.readOurLikes()
                return .succeedRefreshLikes(likes)
            }
            .recover { error in
                .failRefreshLikes(error.localizedDescription)
            }
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        }
        
        func succeedRefreshLikes(
            state: Self,
            environment: Environment,
            likes: [Slashlink]
        ) -> Update<Self> {
            var model = state
            model.likes = likes
            return Update(state: model)
        }
        
        func failRefreshLikes(
            state: Self,
            environment: Environment,
            error: String
        ) -> Update<Self> {
            logger.error("Failed to refresh like: \(error)")
            return Update(state: state)
        }
        
        func succeedUpdateLikeStatus(
            state: Self,
            environment: Environment,
            address: Slashlink,
            liked: Bool
        ) -> Update<Self> {
            
            var model = state
            if liked {
                state.feedback.prepare()
                state.feedback.impactOccurred()
                
                model.likes.append(address)
                return update(
                    state: model,
                    actions: [
                        .refreshLikes,
                        .refreshUpcomingCards
                    ],
                    environment: environment
                )
            }
            
            // Unliked
            model.likes.removeAll(where: { like in like == address })
            
            state.selectionFeedback.prepare()
            state.selectionFeedback.selectionChanged()
            
            return update(
                state: state,
                actions: [
                    .refreshLikes,
                    .refreshUpcomingCards
                ],
                environment: environment
            )
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
                    environment: environment,
                    liked: state.likes.contains(where: { like in like == entry.address })
                )
                
                return .appendCards([card])
            }
            .recover({ error in .noCardsToDraw })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        }

        func setDeck(
            state: Self,
            environment: Environment,
            deck: [CardModel],
            startIndex: Int
        ) -> Update<Self> {
            var model = state
            model.deck = deck
            model.seen = Set(deck.compactMap { card in card.entry })
            model.pointer = startIndex.clamp(min: 0, max: max(0, deck.count - 1))
            model.loadingStatus = deck.count == 0 ? .notFound : .loaded
            
            if let topCard = deck.first {
                return update(
                    state: model,
                    action: .cardPresented(topCard),
                    environment: environment
                )
                .animation(
                    // Only spring in from empty state
                    state.deck.count == 0
                       ? .spring(
                            response: 0.5,
                            dampingFraction: 0.8,
                            blendDuration: 0
                        )
                    : nil
                )
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

        func cardDetailRequested(state: Self, card: CardModel, environment: Environment) -> Update<Self> {
            state.feedback.prepare()
            state.feedback.impactOccurred()
            
            switch card.card {
            case .reward(let message):
                return update(
                    state: state,
                    action: .detailStack(
                        .pushDetail(
                            .editor(MemoEditorDetailDescription(fallback: message))
                        )
                    ),
                    environment: environment
                )
            case let .entry(entry, _, _),
                let .prompt(_, entry, _, _):
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
        }
        
        struct ChooseCardActivityEvent: Codable {
            public static let event: String = "choose_card"
            let address: String
        }
        
        func writeCardChoiceActivity(
            message: String,
            address: Slashlink,
            environment: Environment
        ) throws {
            try environment.database.writeActivity(
                event: ActivityEvent(
                    category: .deck,
                    event: ChooseCardActivityEvent.event,
                    message: message,
                    metadata: ChooseCardActivityEvent(
                        address: address.description
                    )
                )
            )
        }
        
        // Turn the notes held in the "buffer" into a reward card, pushed on top of the deck
        func generateRewardCard(state: Self) -> Update<Self> {
            var model = state
            
            if model.buffer.count >= DeckModel.maxRewardCardBufferSize {
                let entries = model.buffer.compactMap { card in card.entry }
                let openAiFx = Future.detached {
                    let prompt = OpenAIService.prompts.randomElement()
                    guard let prompt = prompt else {
                        return DeckAction.topupDeck
                    }
                    
                    let result = await environment.openAiService.sendRequest(
                        entries: entries,
                        prompt: prompt
                    )
                    
                    switch result {
                    case .success(let msg):
                        return DeckAction.prependCards([
                            CardModel(
                                card: .reward(msg),
                                liked: false
                            )
                        ])
                    case .failure(let error):
                        logger.error("Card generation failed: \(error)")
                        return DeckAction.topupDeck
                    }
                }
                .eraseToAnyPublisher()
                
                model.buffer.removeAll()
                return update(
                    state: model,
                    actions: [.nextCard],
                    environment: environment
                ).mergeFx(openAiFx).animation(.easeOutCubic())
            }
            
            return update(
                state: model,
                actions: [.nextCard],
                environment: environment
            )
        }
        
        // Filter the passed set of related notes down to a candidate set to place into the deck.
        func drawBacklinks(identity: Did, backlinks: Set<EntryStub>) async throws -> [CardModel] {
            let backlinks = backlinks
                .filter({ backlink in !isSeen(entry: backlink) })
                .shuffled()
            
            if backlinks.count == 0 {
                return []
            }
            
            var draw: [CardModel] = []
            for entry in backlinks.prefix(backlinksToDraw) {
                let card = try await toCard(
                    entry: entry,
                    ourIdentity: identity,
                    environment: environment,
                    liked: state.likes.contains(where: { like in like == entry.address })
                )
                
                draw.append(card)
            }
            return draw
        }
        
        func shuffleInBacklinks(
            card: CardModel,
            message: String,
            address: Slashlink,
            backlinks: Set<EntryStub>
        ) -> Update<Self> {
            let fx: Fx<DeckAction> = Future.detached {
                let us = try await environment.noosphere.identity()
                
                try writeCardChoiceActivity(
                    message: message,
                    address: address,
                    environment: environment
                )
                
                let draw = try await drawBacklinks(
                    identity: us,
                    backlinks: backlinks
                )
                guard !draw.isEmpty else {
                    return .topupDeck
                }
                
                return .shuffleCardsUpNext(draw)
            }
            .recover({ error in
                return .topupDeck
            })
            .eraseToAnyPublisher()
            
            
            if AppDefaults.standard.areAiFeaturesEnabled {
                var model = state
                model.buffer.append(card)
                return generateRewardCard(state: model).mergeFx(fx)
            }
            
            return update(
                state: state,
                action: .nextCard,
                environment: environment
            ).mergeFx(fx).animation(.easeOutCubic())
        }
        
        func chooseCard(state: Self, card: CardModel, environment: Environment) -> Update<Self> {
            state.feedback.impactOccurred()
            switch card.card {
            case let .entry(entry, _, related):
                return shuffleInBacklinks(
                    card: card,
                    message: "",
                    address: entry.address,
                    backlinks: related
                )
            case let .prompt(message, entry, _, related):
                return shuffleInBacklinks(
                    card: card,
                    message: message,
                    address: entry.address,
                    backlinks: related
                )
            case .reward(let msg):
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
                    seen: state.seen.map { entry in entry.address },
                    minimumBodyLength: 64
                ) else {
                    return .topupDeck
                }
                
                var draw: [CardModel] = []
                let card = try await toCard(
                    entry: entry,
                    ourIdentity: us,
                    environment: environment,
                    liked: state.likes.contains(where: { like in like == entry.address })
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

        func prependCards(state: Self, entries: [CardModel]) -> Update<Self> {
            var model = state
            for entry in entries {
                model.deck.insert(entry, at: state.pointer)
                
                switch entry.card {
                case let .entry(entry, _, _):
                    model.seen.insert(entry)
                    break
                default:
                    break
                }
            }
            
            return Update(state: model).animation(.easeOutCubic())
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
            
            return Update(state: model).animation(.easeOutCubic())
        }
        
        func requestDeckRoot(
            state: Self,
            environment: AppEnvironment
        ) -> Update<Self> {
            if state.detailStack.details.isEmpty {
                let fx: Fx<DeckAction> = Just(.requestDiscardDeck).eraseToAnyPublisher()
                return Update(state: state, fx: fx)
            }
            
            return DeckDetailStackCursor.update(
                state: state,
                action: .setDetails([]),
                environment: environment
            )
        }

        func noCardsToDraw(state: Self) -> Update<Self> {
            logger.log("No cards to draw")
            return update(state: state, action: .setDeck([], 0), environment: environment)
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
            environment: DeckEnvironment,
            liked: Bool
        ) async throws -> CardModel {
            let links = try readLinks(
                entry: entry,
                identity: entry.did,
                environment: environment
            )
           
            let user = try await environment.userProfile.identifyUser(
                did: entry.did,
                address: entry.address,
                context: nil
            )
            
            let prompt = await environment.prompt.generate(input: entry.excerpt.description)

            return CardModel(
                card: .prompt(
                    message: prompt,
                    entry: entry,
                    author: user,
                    related: links
                ),
                liked: liked
            )
        }
        
        func readLinks(
            entry: EntryStub,
            identity: Did,
            environment: DeckEnvironment,
            replaceStubs: Bool = true
        ) throws -> Set<EntryStub> {
            let backlinks = try environment.database.readEntryBacklinks(
                owner: identity,
                did: entry.did,
                slug: entry.address.slug
            )
            
            let bodyLinks = try environment.database.readEntryBodyLinks(
                owner: identity,
                did: entry.did,
                slug: entry.address.slug
            )
            
            var combinedSet = Set(backlinks)
            combinedSet.formUnion(bodyLinks)
            
            return combinedSet
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
