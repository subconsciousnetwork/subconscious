//
//  SuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI

struct SuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    TitleGroup(
                        title: stub.title,
                        subtitle: stub.slug.description
                    )
                },
                icon: {
                    Image(systemName: "doc")
                }
            ).labelStyle(SuggestionLabelStyle())
        case let .search(stub):
            Label(
                title: {
                    TitleGroup(
                        title: stub.title,
                        subtitle: "New idea"
                    )
                },
                icon: {
                    Image(systemName: "doc.badge.plus")
                }
            ).labelStyle(SuggestionLabelStyle())
        }
    }
}

struct SuggestionLabel_Previews: PreviewProvider {
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
