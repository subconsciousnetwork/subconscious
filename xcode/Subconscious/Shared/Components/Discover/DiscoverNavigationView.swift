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
                VStack(alignment: .leading) {
                    ForEach(store.state.suggestions) { suggestion in
                        StoryUserView(
                            story: StoryUser(
                                entry: AddressBookEntry(
                                    petname: suggestion.neighbor.petname,
                                    did: suggestion.neighbor.identity,
                                    status: .resolved(""),
                                    version: suggestion.neighbor.since ?? ""
                                ),
                                user: UserProfile(
                                    did: suggestion.neighbor.identity,
                                    nickname: suggestion.neighbor.nickname,
                                    address: suggestion.neighbor.address,
                                    pfp: .generated(
                                        suggestion.neighbor.identity
                                    ),
                                    bio: suggestion.neighbor.bio,
                                    category: .human,
                                    ourFollowStatus: .notFollowing,
                                    aliases: [suggestion.neighbor.address.petname].compactMap {
                                        v in v
                                    })
                            ),
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
                            })
                    }
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

