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
    @StateObject var store: Store<DeckModel> = Store(state: DeckModel(), environment: AppEnvironment.default)
    @Environment(\.colorScheme) var colorScheme
    
    let lightBg = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.87, green: 0.86, blue: 0.92), location: 0.00),
            Gradient.Stop(color: Color(red: 0.93, green: 0.81, blue: 0.92), location: 0.38),
            Gradient.Stop(color: Color(red: 0.92, green: 0.92, blue: 0.85), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.9),
        endPoint: UnitPoint(x: 0.5, y: 0)
    )
    
    let darkBg = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.13, green: 0.14, blue: 0.2), location: 0.00),
            Gradient.Stop(color: Color(red: 0.2, green: 0.14, blue: 0.26), location: 0.44),
            Gradient.Stop(color: Color(red: 0.1, green: 0.04, blue: 0.11), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    
    var body: some View {
        VStack(alignment: .leading) {
            if let author = store.state.author {
                HStack(alignment: .center, spacing: AppTheme.unit3) {
                    ProfilePic(pfp: author.pfp, size: .large)
                    
                    if let name = author.toNameVariant(),
                       let slashlink = store.state.topCard?.address {
                        VStack(alignment: .leading, spacing: AppTheme.unit) {
                            PetnameView(
                                name: name,
                                aliases: author.aliases,
                                showMaybePrefix: false
                            )
                            // Trim off peer, we have it above
                            SlashlinkDisplayView(slashlink: Slashlink(slug: slashlink.slug))
                                .theme(slug: .secondary)
                        }
                   }
                }
                
            }
            
            Spacer()
            
            CardStack(
                cards: store.state.deck,
                pointer: store.state.pointer,
                onSwipeRight: { card in
                    store.send(
                        .chooseCard(
                            card
                        )
                    )
                },
                onSwipeLeft: { card in
                    store.send(
                        .skipCard(
                            card
                        )
                    )
                }
            )
            
            Spacer()
            
        }
        .padding(AppTheme.padding)
        .onAppear {
            store.send(.appear)
        }
        .background(
            colorScheme == .dark ? darkBg : lightBg
        )
    }
}

// MARK: Actions
enum DeckAction: Hashable {
    case appear
    case setDeck([EntryStub])
    case chooseCard(EntryStub)
    case skipCard(EntryStub)
    case prependCards([EntryStub])
    case appendCards([EntryStub])
    case topupDeck
    case noCardsToDraw
    
    case nextCard
    case cardPresented(EntryStub)
    
    case succeedLoadAuthorProfile(UserProfile)
    case failLoadAuthorProfile(_ error: String)
}

typealias DeckEnvironment = AppEnvironment

// MARK: Model
struct DeckModel: ModelProtocol {
    typealias Action = DeckAction
    typealias Environment = DeckEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DeckModel"
    )
    
    var deck: [EntryStub] = []
    var seen: [EntryStub] = []
    var pointer: Int = 0
    var author: UserProfile? = nil
    
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
    
    var topCard: EntryStub? {
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
        case .appear:
            var model = state
            
            let fx: Fx<DeckAction> = Future.detached {
                var results: [EntryStub] = []
                let us = try await environment.noosphere.identity()
                var max = 5
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
                
                return .setDeck(results)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case .topupDeck:
            var model = state
            
            let fx: Fx<DeckAction> = Future.detached {
                var results: [EntryStub] = []
                let us = try await environment.noosphere.identity()
                var max = 5
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
                
                return .appendCards(results)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return Update(state: model, fx: fx)
        case let .setDeck(deck):
            var model = state
            model.deck = deck
            model.seen = deck
            model.pointer = 0
            
            if let topCard = deck.first {
                return update(
                    state: model,
                    action: .cardPresented(topCard),
                    environment: environment
                )
            }
            
            return Update(state: model)
        case let .chooseCard(entry):
            var model = state
            
            let fx: Fx<DeckAction> = Future.detached {
                let us = try await environment.noosphere.identity()
                var backlinks = try environment.database
                    .readEntryBacklinks(owner: us, did: entry.did, slug: entry.address.slug)
                    .filter({ backlink in !isSeen(card: backlink) && !isTooShort(card: backlink) })
                backlinks.shuffle()
                
                if backlinks.count == 0 {
                    return .topupDeck
                }
                
                return .appendCards(Array(backlinks.prefix(3)))
            }
            .recover({ error in
                return .noCardsToDraw
            })
            .eraseToAnyPublisher()
            
            return update(state: model, action: .nextCard, environment: environment).mergeFx(fx)
        case let .skipCard(entry):
            var model = state
            model.pointer += 1
            
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
                
                return .appendCards(results)
            }
            .recover({ error in .appendCards([]) })
            .eraseToAnyPublisher()
            
            return Update(state: model, fx: fx)
        case let .appendCards(entries):
            var model = state
            for entry in entries.filter({ entry in !inDeck(card: entry) }) {
                
                // insert entry into deck at random index (not the first 2 spots)
                Self.insertAtRandomIndex(item: entry, into: &model.deck, skippingFirst: state.pointer + 2)
                model.seen.append(entry)
            }
            
            return Update(state: model)
        case let .prependCards(entries):
            var model = state
            for entry in entries.filter({ entry in !inDeck(card: entry) }) {
                model.deck.insert(entry, at: 0)
                model.seen.append(entry)
            }
            
            return Update(state: model)
        case .noCardsToDraw:
            logger.log("No cards to draw")
            return Update(state: state)
        case .nextCard:
            var model = state
            model.pointer += 1
            
            if let topCard = model.topCard {
                return update(state: model, action: .cardPresented(topCard), environment: environment)
            }
            
            return Update(state: model)
        case .cardPresented(let card):
            logger.log("Card presented \(card.id)")
            
            let fx: Fx<DeckAction> = Future.detached {
                let user = try await environment.userProfile.identifyUser(did: card.did, address: card.address, context: nil)
                return .succeedLoadAuthorProfile(user)
            }
                .recover { error in .failLoadAuthorProfile(error.localizedDescription) }
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case .succeedLoadAuthorProfile(let author):
            var model = state
            model.author = author
            return Update(state: model).animation(.spring(duration: 0.2))
        case .failLoadAuthorProfile(let error):
            logger.log("Failed to load author profile: \(error)")
            return Update(state: state)
        }
        
        func isTooShort(card: EntryStub) -> Bool {
            return card.excerpt.base.count < 64
        }
        
        func isSeen(card: EntryStub) -> Bool {
            return state.seen.contains(where: { entry in entry == card })
        }
        
        func inDeck(card: EntryStub) -> Bool {
            return state.deck.contains(where: { entry in entry == card })
        }
    }
}
