//
//  Transclude2View.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/22/23.
//

import SwiftUI

/// A transitional transclude form that does not have a PFP.
/// We'll replace uses of Transclude2View with TranscludeView once we integrate
/// pfps throughout the app.
struct Transclude2View: View {
    var author: UserProfile
    var address: Slashlink
    var excerpt: String
    var action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                VStack(alignment: .leading, spacing: AppTheme.unit2) {
                    BylineSmView(
                        pfp: author.pfp,
                        slashlink: address
                    )
                    Text(excerpt)
                        .lineLimit(5)
//                    SlashlinkDisplayView(slashlink: address)
//                        .theme(base: .secondary, slug: .secondary)
                }
            }
        )
        .buttonStyle(TranscludeButtonStyle())
    }
}

struct Transclude2View_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Transclude2View(
                author: UserProfile.dummyData(),
                address: Slashlink("/short")!,
                excerpt: "Short.",
                action: { }
            )
            Transclude2View(
                author: UserProfile.dummyData(),
                address: Slashlink("@gordon/loomings")!,
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation.",
                action: { }
            )
            Transclude2View(
                author: UserProfile.dummyData(),
                address: Slashlink("/loomings")!,
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely",
                action: { }
            )
            Transclude2View(
                author: UserProfile.dummyData(),
                address: Slashlink("did:subconscious:local/loomings")!,
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely",
                action: { }
            )
            Transclude2View(
                author: UserProfile.dummyData(),
                address: Slashlink("did:key:abc123/loomings")!,
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely",
                action: { }
            )
        }
    }
}
