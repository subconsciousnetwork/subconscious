//
//  LinkSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct LinkSuggestionLabelView: View, Equatable {
    var suggestion: LinkSuggestion

    var body: some View {
        switch suggestion {
        case .entry(let link):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(link.title),
                        subtitle: SlashlinkDisplayView(
                            slashlink: link.address,
                            baseColor: Color.secondary,
                            slugColor: Color.secondary,
                            labelColor: Color.secondary
                        )
                    )
                },
                icon: {
                    Image(systemName: "link")
                }
            )
        case .new(let link):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(link.title),
                        subtitle: Text("Link to new note")
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
                    address: Slashlink(
                        "@here/a-muse-is-more-interesting-than-an-oracle"
                    )!,
                    title: "A muse is more interesting than an oracle"
                )
            )
        )
    }
}
