//
//  DeckNavigationView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 21/11/2023.
//

import Foundation
import ObservableStore
import SwiftUI

struct DeckNavigationView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<DeckModel>
    @Environment(\.colorScheme) var colorScheme
    
    var detailStack: ViewStore<DetailStackModel> {
        store.viewStore(
            get: DeckDetailStackCursor.get,
            tag: DeckDetailStackCursor.tag
        )
    }
    
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            VStack(alignment: .leading) {
                if case let .entry(_, author, _) = store.state.topCard?.card,
                   let name = author.toNameVariant() {
                    HStack(
                        alignment: .center,
                        spacing: AppTheme.unit3
                    ) {
                        ProfilePic(
                            pfp: author.pfp,
                            size: .large
                        )
                        
                        PetnameView(
                            name: name,
                            aliases: [],
                            showMaybePrefix: false
                        )
                    }
                    .onTapGesture {
                        detailStack.send(
                            .pushDetail(
                                .profile(UserProfileDetailDescription(address: author.address))
                            )
                        )
                    }
                }
                
                if (store.state.deck.isEmpty) {
                    VStack(alignment: .center) {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                CardStack(
                    deck: store.state.deck,
                    current: store.state.pointer,
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
                    },
                    onSwipeStart: {
                        store.send(.cardPickedUp)
                    },
                    onSwipeAbandoned: {
                        store.send(.cardReleased)
                    },
                    onCardTapped: { card in
                        store.send(.cardTapped(card))
                    }
                )
                .offset(x: 0, y: -AppTheme.unit * 8)
            }
            .padding(AppTheme.padding)
            .frame(maxWidth: .infinity)
            .background(
                colorScheme == .dark ? DeckTheme.darkBg : DeckTheme.lightBg
            )
        }
    }
}
