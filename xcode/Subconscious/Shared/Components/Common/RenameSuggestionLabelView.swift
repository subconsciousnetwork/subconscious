//
//  RenameSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSuggestionLabelView: View {
    var suggestion: RenameSuggestion
    var body: some View {
        switch suggestion {
        case .merge(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: entryLink.slug.description,
                        subtitle: "Merge ideas"
                    )
                },
                icon: {
                    Image(systemName: "square.and.arrow.down.on.square")
                }
            )
        case .rename(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: entryLink.slug.description,
                        subtitle: "Rename idea"
                    )
                },
                icon: {
                    Image(systemName: "pencil")
                }
            )
        }
    }
}

struct RenameSuggestionLabel_Previews: PreviewProvider {
    static var previews: some View {
        RenameSuggestionLabelView(
            suggestion: .rename(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
