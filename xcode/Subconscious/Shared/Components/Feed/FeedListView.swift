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
                        onRequestDetail: { address, excerpt in
                            store.send(
                                .detailStack(
                                    .pushDetail(
                                        MemoDetailDescription.from(
                                            address: address,
                                            fallback: excerpt
                                        )
                                    )
                                )
                            )
                        },
                        onLink: { context, link in
                            store.send(
                                .detailStack(
                                    .findAndPushLinkDetail(
                                        context: context,
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
