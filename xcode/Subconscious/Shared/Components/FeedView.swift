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
        VStack {
            ForEach(store.state.feed.stories) { story in
                StoryView(
                    story: story,
                    action: { link in
                    
                    }
                )
            }
        }
    }
}
