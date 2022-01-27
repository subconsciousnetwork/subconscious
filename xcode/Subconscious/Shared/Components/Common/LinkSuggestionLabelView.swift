//
//  LinkSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

// A second label view that does not include the action label
struct LinkSuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(stub.title)
                            .lineLimit(1)
                            .foregroundColor(Color.text)
                            .frame(height: AppTheme.icon)
                        Text(#"Link to "\#(stub.slug.description)""#)
                            .lineLimit(1)
                            .foregroundColor(Color.secondaryText)
                            .frame(height: AppTheme.icon)
                    }
                },
                icon: {
                    Image(systemName: "link")
                }
            ).labelStyle(SuggestionLabelStyle())
        case let .search(stub):
            Label(
                title: {
                    TitleGroup(
                        title: stub.title,
                        subtitle: #"Link to "\#(stub.slug)""#
                    )
                },
                icon: {
                    Image(systemName: "link.badge.plus")
                }
            ).labelStyle(SuggestionLabelStyle())
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
