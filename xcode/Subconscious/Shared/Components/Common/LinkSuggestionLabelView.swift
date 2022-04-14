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
        case .entry(let wikilink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(wikilink.text),
                        subtitle: Text(
                            #"Link to "\#(String(describing: wikilink.slug))""#
                        )
                    )
                },
                icon: {
                    Image(systemName: "link")
                }
            )
        case .new(let wikilink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(wikilink.text),
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
                Wikilink(
                    slug: Slug("floop")!
                )
            )
        )
    }
}
