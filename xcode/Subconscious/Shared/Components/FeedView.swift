//
//  FeedView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/22.
//

import SwiftUI

struct FeedView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                ForEach(store.state.feed.stories) { story in
                    StoryView(
                        story: story,
                        action: { link in
                            store.send(
                                AppAction.requestDetail(
                                    slug: link.slug,
                                    fallback: link.linkableTitle,
                                    autofocus: false
                                )
                            )
                        }
                    )
                }
            }
        }
    }
}
