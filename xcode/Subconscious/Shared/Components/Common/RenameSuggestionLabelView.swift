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
                        title: Text(verbatim: parent.slug.description),
                        subtitle: Text("Merge notes")
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
                        title: Text(verbatim: to.slug.description),
                        subtitle: Text("Edit link")
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
                from: MemoAddress.public(
                    Slashlink("@here/loomings")!
                ),
                to: MemoAddress.public(
                    Slashlink("@here/the-lee-shore")!
                )
            )
        )
    }
}
