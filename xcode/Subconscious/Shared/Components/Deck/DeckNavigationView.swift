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
    
    var detailStack: ViewStore<DetailStackModel> {
        store.viewStore(
            get: FeedDetailStackCursor.get,
            tag: FeedDetailStackCursor.tag
        )
    }
    
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            VStack {
                switch (store.state.status, store.state.entries) {
                case (.loading, _):
                    FeedPlaceholderView()
                case let (.loaded, .some(feed)):
                    switch feed.count {
                    case 0:
                        FeedEmptyView(
                            onRefresh: { app.send(.syncAll) }
                        )
                    default:
                        FeedListView(
                            feed: feed,
                            store: store
                        )
                    }
                case (.notFound, _):
                    NotFoundView()
                default:
                    EmptyView()
                }
            }
            .background(Color.background)
            .refreshable {
                app.send(.syncAll)
            }
            .onAppear {
                store.send(.fetchFeed)
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                MainToolbar(
                    app: app,
                    profileAction: {
                        store.send(.detailStack(.requestOurProfileDetail))
                    }
                )
                
                ToolbarItemGroup(placement: .principal) {
                    HStack {
                        Text("Feed").bold()
                    }
                }
            }
        }
    }
}
