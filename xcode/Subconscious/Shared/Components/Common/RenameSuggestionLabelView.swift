//
//  RenameSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case .entry(let entryLink):
            Label(
                title: {
                    TitleGroup(
                        title: entryLink.slug.description,
                        subtitle: "Merge ideas"
                    )
                },
                icon: {
                    Image(systemName: "arrow.triangle.merge")
                }
            )
        case .search(let entryLink):
            Label(
                title: {
                    TitleGroup(
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
            suggestion: .search(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
