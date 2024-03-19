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
        case .cardDetailRequested(let card):
            store.send(.cardDetailRequested(card))
        case let .entry(entryNotification):
            switch entryNotification {
            case let .requestLinkDetail(link):
                store.send(
                    .detailStack(.findAndPushLinkDetail(link))
                )
            case let .quote(address):
                store.send(.detailStack(.pushQuoteInNewDetail(address)))
            case let .like(address):
                store.send(.requestUpdateLikeStatus(address, liked: true))
            case let .unlike(address):
                store.send(.requestUpdateLikeStatus(address, liked: false))
            case .delete, .requestDetail:
                break
            }
        }
    }
    
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            VStack(alignment: .leading) {
                switch store.state.loadingStatus {
                case .loading, .initial:
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
                    
                    MiniCardStackView(
                        cards: store.state.buffer,
                        mode: .stack
                    )
                    
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
            .alert(
                isPresented: store.binding(
                    get: \.aiPromptPresented,
                    tag: DeckAction.setAiPromptPresented
                )
            ){
                Alert(title: Text("Prompt"),
                      message: Text(store.state.aiPrompt),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}
