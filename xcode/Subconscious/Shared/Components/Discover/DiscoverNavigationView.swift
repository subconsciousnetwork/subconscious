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
                                    petname: suggestion.petname,
                                    did: suggestion.identity,
                                    status: .resolved(""),
                                    version: suggestion.since ?? ""
                                ),
                                user: UserProfile(
                                    did: suggestion.identity,
                                    nickname: nil,
                                    address: suggestion.address,
                                    pfp: .generated(
                                        suggestion.identity
                                    ),
                                    bio: nil,
                                    category: .human,
                                    ourFollowStatus: .notFollowing,
                                    aliases: [suggestion.address.petname].compactMap {
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

