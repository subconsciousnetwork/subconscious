//
//  ThreadListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

struct ThreadListView: View {
    var threads: [Thread]

    var body: some View {
        VStack(spacing: 8) {
            if threads.count > 0 {
                UnfoldedThreadView(thread: threads[0])
            }
            if threads.count > 1 {
                ForEach(threads[1...]) { thread in
                    ThickDivider().padding(.vertical, 4)
                    FoldedThreadView(thread: thread)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ThreadListView(
                threads: [
                    Thread(
                        id: UUID(),
                        title: "Tenuki",
                        blocks: [
                            Block.text(TextBlock(text: "Roughly refers to doing things for no reason, or just for fun, and then they happen to play a critical role later.")),
                            Block.text(TextBlock(text: "One of the most common novice mistakes is getting locked into the local fight and continuing to play there when there are larger plays elsewhere. Tenuki is always an option.")),
                            Block.text(TextBlock(text: "Following this advice many advanced amateurs acquired the habit to make coffee breaks regularly, that is playing tenuki - often from fights - to play a small move somewhere.")),
                            Block.heading(HeadingBlock(text: "Proverbs")),
                            Block.text(TextBlock(text: "A debatable proverb says: If it's worth only 15 points, play tenuki.")),
                            Block.text(TextBlock(text: "Yet another debatable proverb counsels us to play tenuki when at a loss as where to play locally, When in doubt, tenuki.")),
                        ]
                    ),
                    Thread(
                        id: UUID(),
                        title: "Civilizational CPUs",
                        blocks: [
                            Block.text(TextBlock(text: "When we change the efficiency of knowledge operations, we change the shape of society.")),
                            Block.text(TextBlock(text: "Juxtaposing with this @SeshatDatabank paper. Institutions are like civilizational CPUs, making group coordination decisions, and civilizations scale until their CPUs are swamped by the information environment.")),
                            Block.heading(HeadingBlock(text: "Heading block")),
                            Block.text(TextBlock(text: "Some more text")),
                        ]
                    ),
                ]
            )
        }
    }
}
