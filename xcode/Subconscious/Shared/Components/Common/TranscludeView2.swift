//
//  TranscludeView2.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/22/23.
//

import SwiftUI

/// A transitional transclude form that does not have a PFP.
/// We'll replace uses of Transclude2View with TranscludeView once we integrate
/// pfps throughout the app.
struct Transclude2View: View {
    var petname: String?
    var slashlink: String
    var title: String
    var excerpt: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            HStack {
                Text(title)
                    .bold()
                Spacer()
            }
            Text(excerpt)
                .lineLimit(5)
            HStack(spacing: 0) {
                if let petname = petname {
                    Text(verbatim: petname)
                        .fontWeight(.semibold)
                }
                Text(verbatim: slashlink)
            }
            .foregroundColor(.secondary)
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
        Transclude2View(
            petname: "@gordon",
            slashlink: "/loomings",
            title: "Loomings",
            excerpt: "Call me Ishmael. Some years ago- never mind how long precisely- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation."
        )
    }
}
