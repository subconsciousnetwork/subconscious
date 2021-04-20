//
//  ThreadView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/6/21.
//

import SwiftUI

/// A foldable thread
struct ThreadView: View {
    var thread: Thread
    @Binding var isFolded: Bool
    var maxBlocksWhenFolded = 1

    var body: some View {
        VStack(spacing: 0) {
            if let title = thread.title {
                Text(title)
                    .font(.body)
                    .bold()
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }

            if thread.blocks.count > maxBlocksWhenFolded && isFolded {
                ForEach(
                    thread.blocks[0..<max(1, maxBlocksWhenFolded)]
                ) { block in
                    BlockView(block: block)
                }

                HStack {
                    Button(action: {
                        self.isFolded.toggle()
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color("IconSecondary"))
                            .padding(8)
                    }
                    .background(Color("ButtonSecondary"))
                    .cornerRadius(8)
                    .padding(.vertical, 4)

                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.top, 8)
                .padding(.leading, 16)
                .padding(.trailing, 16)
            } else {
                ForEach(thread.blocks) { block in
                    BlockView(block: block)
                }
            }
        }
    }
}

struct FoldedThreadView: View {
    @State private var isFolded = true
    var thread: Thread
    var body: some View {
        ThreadView(
            thread: thread,
            isFolded: $isFolded
        )
    }
}

struct UnfoldedThreadView: View {
    @State private var isFolded = false
    var thread: Thread
    var body: some View {
        ThreadView(
            thread: thread,
            isFolded: $isFolded
        )
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        FoldedThreadView(
            thread: Thread(
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
            )
        )
    }
}
