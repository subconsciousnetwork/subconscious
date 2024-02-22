//
//  DiscoverNavigationView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/2/2024.
//

import Foundation
import ObservableStore
import SwiftUI

struct DiscoverNavigationView: View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<DiscoverModel>
    @Environment(\.colorScheme) var colorScheme
    
    var detailStack: ViewStore<DetailStackModel> {
        store.viewStore(
            get: DiscoverDetailStackCursor.get,
            tag: DiscoverDetailStackCursor.tag
        )
    }
   
    var body: some View {
        DetailStackView(app: app, store: detailStack) {
            ScrollView {
                VStack {
                    switch store.state.loadingStatus {
                    case .loading:
                        Spacer()
                        ProgressView()
                        Spacer()
                    case .loaded:
                        VStack(alignment: .leading) {
                            ForEach(store.state.suggestions) { suggestion in
                                DiscoverUserView(
                                    suggestion: suggestion,
                                    action: { address in
                                        detailStack.send(
                                            .pushDetail(
                                                .profile(
                                                    UserProfileDetailDescription(
                                                        address: address
                                                    )
                                                )
                                            )
                                        )
                                    },
                                    pendingFollow: store.state.pendingFollows.contains(where: { pending in
                                        pending == suggestion.neighbor
                                    }),
                                    onFollow: { neighbor in
                                        store.send(.requestFollowNeighbor(neighbor))
                                    },
                                    onUnfollow: { neighbor in
                                        store.send(.requestUnfollowNeighbor(neighbor))
                                    }
                                )
                            }
                        }
                        .padding(AppTheme.padding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .notFound:
                        NotFoundView()
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                MainToolbar(
                    app: app
                )
            }
        }
    }
}

