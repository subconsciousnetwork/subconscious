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
    
    func notify(notification: CardStackNotification) {
        switch notification {
        case let .swipeLeft(card):
            store.send(.skipCard(card))
        case let .swipeRight(card):
            store.send(.chooseCard(card))
        case .swipeStarted:
            store.send(.cardPickedUp)
        case .swipeAbandoned:
            store.send(.cardReleased)
        case let .cardTapped(card):
            store.send(.cardTapped(card))
        case let .linkTapped(link):
            store.send(
                .detailStack(.findAndPushLinkDetail(link))
            )
        case let .cardQuoted(address):
            store.send(.detailStack(.pushQuoteInNewDetail(address)))
        case let .cardLiked(address):
            store.send(.requestLikeEntry(address))
        case let .cardUnliked(address):
            store.send(.requestUnlikeEntry(address))
        }
    }
    
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            VStack(alignment: .leading) {
                switch store.state.loadingStatus {
                case .loading:
                    VStack(alignment: .center) {
                        Spacer()
                        CardShuffleView()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    if let author = store.state.topCard?.author,
                       let name = author.toNameVariant() {
                        Button(
                            action: {
                                detailStack.send(
                                    .pushDetail(
                                        .profile(
                                            UserProfileDetailDescription(
                                                address: author.address
                                            )
                                        )
                                    )
                                )
                                
                            },
                            label: {
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
                                .transition(
                                    .push(
                                        from: .bottom
                                    )
                                )
                            }
                        )
                    }
                    
                    CardStack(
                        deck: store.state.deck,
                        current: store.state.pointer,
                        notify: notify
                    )
                    .offset(y: -AppTheme.unit * 8)
                    
                case .notFound:
                    HStack {
                        Spacer()
                        VStack(spacing: AppTheme.unit * 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 64))
                            VStack(spacing: AppTheme.unit) {
                                Text("Your Subconscious is empty")
                            }
                            
                            VStack(spacing: AppTheme.unit) {
                                Text(
                                """
                                Become totally empty
                                Quiet the restlessness of the mind
                                Only then will you witness everything unfolding from emptiness.
                                """
                                )
                                .italic()
                                Text(
                                    "Lao Tzu"
                                )
                            }
                            .frame(width: 240)
                            .font(.caption)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(AppTheme.padding)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                MainToolbar(
                    app: app
                )
            }
        }
    }
}
