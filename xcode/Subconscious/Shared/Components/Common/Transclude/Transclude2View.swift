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
    var address: Slashlink
    var excerpt: String
    var action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                VStack(alignment: .leading, spacing: AppTheme.unit) {
                    Text(excerpt)
                        .lineLimit(5)
                    SlashlinkBylineView(slashlink: address)
                        .theme(petname: Color.secondary)
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
                address: Slashlink("/short")!,
                excerpt: "Short.",
                action: { }
            )
            Transclude2View(
                address: Slashlink("@gordon/loomings")!,
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation.",
                action: { }
            )
            Transclude2View(
                address: Slashlink("/loomings")!,
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation.",
                action: { }
            )
        }
    }
}
