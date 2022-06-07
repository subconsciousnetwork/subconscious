//
//  RenameSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSuggestionLabelView: View, Equatable {
    var suggestion: RenameSuggestion

    var body: some View {
        switch suggestion {
        case let .merge(parent, _):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(parent.linkableTitle),
                        subtitle: Text("Merge ideas")
                    )
                },
                icon: {
                    Image(systemName: "square.and.arrow.down.on.square")
                }
            )
        case let .move(_, to):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(to.linkableTitle),
                        subtitle: Text("Rename idea")
                    )
                },
                icon: {
                    Image(systemName: "pencil")
                }
            )
        case let .retitle(_, to):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(to.linkableTitle),
                        subtitle: Text("Update title")
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
            suggestion: .move(
                from: EntryLink(
                    slug: Slug("loomings")!,
                    title: "Loomings"
                ),
                to: EntryLink(
                    slug: Slug("the-lee-shore")!,
                    title: "The Lee Shore"
                )
            )
        )
    }
}
