//
//  LinkSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct LinkSuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case .entry(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: entryLink.slug.description,
                        subtitle: #"Link to "\#(entryLink.title)""#
                    )
                },
                icon: {
                    Image(systemName: "link")
                }
            )
        case .search(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: entryLink.slug.description,
                        subtitle: #"Link to new idea"#
                    )
                },
                icon: {
                    Image(systemName: "link.badge.plus")
                }
            )
        }
    }
}


struct LinkSuggestionLabel_Previews: PreviewProvider {
    static var previews: some View {
        LinkSuggestionLabelView(
            suggestion: .search(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
