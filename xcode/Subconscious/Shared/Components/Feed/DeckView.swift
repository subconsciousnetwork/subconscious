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
    
    var body: some View {
        VStack {
            Text("\(store.state.deck.count) cards in deck")
            if let topCard = store.state.deck.first {
                TranscludeView(entry: topCard, onRequestDetail: { }, onLink: { _ in })
                
                Button(action: { store.send(.skipCard(topCard)) }, label: { Text("Skip") })
                Button(action: { store.send(.chooseCard(topCard)) }, label: { Text("Choose") })
            }
        }
        .onAppear {
            store.send(.appear)
        }
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
                for _ in 0..<5 {
                    guard let entry = environment.database.readRandomEntry(owner: us) else {
                        break
                    }
                    
                    guard !isTooShort(card: entry) else {
                        break
                    }
                    
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
                for _ in 0..<5 {
                    guard let entry = environment.database.readRandomEntry(owner: us) else {
                        break
                    }
                    
                    guard !isSeen(card: entry), !isTooShort(card: entry) else {
                        break
                    }
                    
                    results.append(entry)
                }
                
                return .appendCards(results)
            }
            .recover({ error in .setDeck([]) })
            .eraseToAnyPublisher()
            
            return Update(state: state, fx: fx)
        case let .setDeck(deck):
            var model = state
            model.deck = deck
            model.seen = deck
            return Update(state: model)
        case let .chooseCard(entry):
            var model = state
            model.deck = model.deck.filter({ card in card != entry })
            
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
            return Update(state: model, fx: fx)
        case let .skipCard(entry):
            var model = state
            model.deck = model.deck.filter({ card in card != entry })
            
            if model.deck.count == 0 {
                return update(state: model, action: .topupDeck, environment: environment)
            }
            
            return Update(state: model)
        case let .appendCards(entries):
            var model = state
            for entry in entries.filter({ entry in !inDeck(card: entry) }) {
                model.deck.append(entry)
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
