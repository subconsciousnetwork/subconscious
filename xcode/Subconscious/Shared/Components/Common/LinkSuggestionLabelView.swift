//
//  LinkSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct LinkSuggestionLabelView: View {
    var suggestion: LinkSuggestion
    var body: some View {
        switch suggestion {
        case .entry(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(String(entryLink.slug)),
                        subtitle: Text(#"Link to "\#(entryLink.title)""#)
                    )
                },
                icon: {
                    Image(systemName: "link")
                }
            )
        case .new(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(String(entryLink.slug)),
                        subtitle: Text("Link to new idea")
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
            suggestion: .new(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
