//
//  SubtextView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/18/23.
//

import SwiftUI

struct RenderableBlock: Hashable {
    var block: Subtext.Block
    var entries: [EntryStub]
}

struct SubtextView: View {
    private static var renderer = SubtextAttributedStringRenderer()
    var subtext: Subtext
    var transcludePreviews: [Slashlink: EntryStub]
    var onViewTransclude: (Slashlink) -> Void
    
    private func entries(for block: Subtext.Block) -> [EntryStub] {
        block.slashlinks
            .compactMap { link in
                guard let slashlink = link.toSlashlink() else {
                    return nil
                }
                
                return transcludePreviews[slashlink]
            }
            .filter { entry in
                // Avoid empty transclude blocks
                entry.excerpt.count > 0
            }
    }
    
    var blocks: [RenderableBlock] {
        subtext.blocks.map { block in
            return RenderableBlock(block: block, entries: self.entries(for: block))
        }
    }
    
    func shouldReplaceBlockWithTransclude(block: Subtext.Block) -> Bool {
        var count = 0
        for inline in block.inline {
            switch (inline) {
            case .slashlink(let slashlink):
                count += slashlink.span.count
                continue
            case _:
                continue
            }
        }
        
        return block.body()
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespaces)
            .count <= count
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(blocks, id: \.self) { renderable in
                if renderable.entries.isEmpty ||
                    !shouldReplaceBlockWithTransclude(block: renderable.block) {
                    Text(Self.renderer.render(renderable.block.description))
                }
                
                ForEach(renderable.entries, id: \.self) { entry in
                    if let author = entry.author {
                        TranscludeView(
                            author: author,
                            address: entry.address,
                            excerpt: entry.excerpt,
                            action: {
                                onViewTransclude(entry.address)
                            }
                        )
                    }
                }
            }
        }
        .transition(.slide)
        .expandAlignedLeading()
    }
}

struct SubtextView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SubtextView(
                subtext: Subtext(
                    markup: """
                    # The Prophet, Kahlil Gibran
                    
                    People of [[Orphalese]], the wind bids me leave you.
                    
                    Less _hasty_ am I than the *wind*, yet I must go.
                    
                    http://example.com
                    
                    We [[wanderers]], ever seeking the lonelier way, begin no day where we have ended another day; and no sunrise finds us where sunset left us.
                    
                    /wanderer-your-footsteps-are-the-road
                    
                    Even while the `earth` sleeps we travel.
                    
                    > We are the seeds of the tenacious plant, and it is in our ripeness and our fullness of heart that we are given to the wind and are scattered.
                    
                    Brief were my days among you, and briefer still the words I have spoken.
                    
                    But should my /voice fade in your ears, and my love vanish in your /memory, then I will come again,
                    
                    And with a richer heart and lips more yielding to the spirit will I speak.
                    
                    Yea, I shall return with the tide,
                    """
                ),
                transcludePreviews: [
                    Slashlink("/wanderer-your-footsteps-are-the-road")!: EntryStub(
                        address: Slashlink(
                            "/wanderer-your-footsteps-are-the-road"
                        )!,
                        excerpt: "hello mother",
                        modified: Date.now,
                        author: UserProfile.dummyData()
                    ),
                    Slashlink("/voice")!: EntryStub(
                        address: Slashlink(
                            "/voice"
                        )!,
                        excerpt: "hello father",
                        modified: Date.now,
                        author: UserProfile.dummyData()
                    ),
                    Slashlink("/memory")!: EntryStub(
                        address: Slashlink(
                            "/memory"
                        )!,
                        excerpt: "hello world",
                        modified: Date.now,
                        author: UserProfile.dummyData()
                    )
                ],
                onViewTransclude: {
                    _ in 
                }
            )
        }
    }
}
