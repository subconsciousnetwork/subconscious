//
//  SubtextView.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/18/23.
//

import SwiftUI

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

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(subtext.blocks, id: \.self) { block in
                Text(Self.renderer.render(block.description))
                ForEach(self.entries(for: block), id: \.self) { entry in
                    Transclude2View(
                        address: entry.address,
                        excerpt: entry.excerpt,
                        action: {
                            onViewTransclude(entry.address)
                        }
                    )
                }
            }
        }
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
                    Slashlink("/wanderer-your-footsteps-are-the-road")!: EntryStub(address: Slashlink("/wanderer-your-footsteps-are-the-road")!, excerpt: "hello mother", modified: Date.now),
                    Slashlink("/voice")!: EntryStub(address: Slashlink("/voice")!, excerpt: "hello father", modified: Date.now),
                    Slashlink("/memory")!: EntryStub(address: Slashlink("/memory")!, excerpt: "hello world", modified: Date.now)
                ],
                onViewTransclude: { _ in }
            )
        }
    }
}
