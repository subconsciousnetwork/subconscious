//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/28/22.
//

import SwiftUI

struct SuggestionLabelView: View {
    var suggestion: Suggestion

    private func readTitle(_ text: String) -> String {
        text.isEmpty ? "Untitled" : text
    }

    var body: some View {
        switch suggestion {
        case .entry(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: readTitle(entryLink.title),
                        subtitle: entryLink.slug.description
                    )
                },
                icon: {
                    Image(systemName: "doc")
                }
            )
        case .search(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: readTitle(entryLink.title),
                        subtitle: entryLink.slug.description
                    )
                },
                icon: {
                    Image(systemName: "doc.badge.plus")
                }
            )
        }
    }
}

struct SuggestionLabelView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionLabelView(
            suggestion: .search(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
