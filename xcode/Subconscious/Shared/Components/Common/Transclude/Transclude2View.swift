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
    var address: MemoAddress
    var excerpt: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            Text(excerpt)
                .lineLimit(5)
            SlashlinkBylineView(slashlink: address.toSlashlink())
                .theme(petname: Color.secondary)
        }
        .padding(.vertical, AppTheme.unit3)
        .padding(.horizontal, AppTheme.unit4)
        .overlay(
            RoundedRectangle(
                cornerRadius: AppTheme.cornerRadiusLg
            )
            .stroke(Color.separator, lineWidth: 0.5)
        )
    }
}

struct Transclude2View_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Transclude2View(
                address: MemoAddress.public(Slashlink("/short")!),
                excerpt: "Short."
            )
            Transclude2View(
                address: MemoAddress.public(Slashlink("@gordon/loomings")!),
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation."
            )
            Transclude2View(
                address: MemoAddress.public(Slashlink("/loomings")!),
                excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation."
            )
        }
    }
}
