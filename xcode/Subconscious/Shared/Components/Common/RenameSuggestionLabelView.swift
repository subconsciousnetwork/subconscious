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
                        .frame(width: AppTheme.icon, height: AppTheme.icon)
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
                        .frame(width: AppTheme.icon, height: AppTheme.icon)
                }
            )
        }
    }
}

struct RenameSuggestionLabel_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RenameSuggestionLabelView(
                suggestion: .move(
                    from: Slashlink("@here/loomings")!,
                    to: Slashlink("@here/the-lee-shore")!
                )
            )
            RenameSuggestionLabelView(
                suggestion: .merge(
                    parent: Slashlink("/loomings")!,
                    child: Slashlink("/the-lee-shore")!
                )
            )
            RenameSuggestionLabelView(
                suggestion: .move(
                    from: Slashlink("did:key:abc123/loomings")!,
                    to: Slashlink("did:key:abc123/the-lee-shore")!
                )
            )
            RenameSuggestionLabelView(
                suggestion: .merge(
                    parent: Slashlink("did:subconscious:local/loomings")!,
                    child: Slashlink("did:subconscious:local/the-lee-shore")!
                )
            )
        }
    }
}
