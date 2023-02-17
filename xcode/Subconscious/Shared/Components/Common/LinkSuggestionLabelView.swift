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
                        subtitle: Text(
                            #"Link to "\#(String(describing: link.address.slug))""#
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
                    address: MemoAddress(
                        slug: Slug("A muse is more interesting than an oracle")!,
                        audience: .public
                    )
                )
            )
        )
    }
}
