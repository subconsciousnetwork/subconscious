//
//  FeedListView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 13/10/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct FeedListView: View {
    var feed: [StoryEntry]
    var store: Store<FeedModel>
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Divider()
                
                ForEach(feed) { story in
                    StoryEntryView(
                        story: story,
                        action: { address, _ in
                            store.send(
                                .detailStack(
                                    .pushDetail(
                                        MemoDetailDescription.from(
                                            address: address,
                                            fallback: ""
                                        )
                                    )
                                )
                            )
                        },
                        onLink: { link in
                            store.send(
                                .detailStack(
                                    .findAndPushLinkDetail(
                                        address: story.entry.address,
                                        link: link
                                    )
                                )
                            )
                        }
                    )
                    
                    Divider()
                }
                
                FabSpacerView()
            }
        }
    }
}
