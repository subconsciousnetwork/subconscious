//
//  NotebookFeedView.swift
//  Subconscious
//
//  Created by Ben Follington on 26/8/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct NotebookFeedView : View {
    @ObservedObject var app: Store<AppModel>
    @ObservedObject var store: Store<NotebookModel>
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Feed")
                    .bold()
                    .padding()
                
                if let feed = store.state.feed {
                    ForEach(feed) { entry in
                        if let author = entry.author {
                            StoryEntryView(
                                story: StoryEntry(
                                    author: author,
                                    entry: entry
                                ),
                                action: { address, _ in
                                    store.send(.pushDetail(
                                        MemoDetailDescription.from(
                                            address: address,
                                            fallback: ""
                                        )
                                    ))
                                }
                            )
                        }
                    }
                } else {
                    Text("Feeding...")
                }
            }
        }
        .onAppear {
            store.send(.requestFeed)
        }
    }
}
