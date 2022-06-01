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
        case .merge(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(entryLink.toLinkableTitle()),
                        subtitle: Text("Merge ideas")
                    )
                },
                icon: {
                    Image(systemName: "square.and.arrow.down.on.square")
                }
            )
        case .rename(let entryLink):
            Label(
                title: {
                    TitleGroupView(
                        title: Text(entryLink.toLinkableTitle()),
                        subtitle: Text("Rename idea")
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
            suggestion: .rename(
                EntryLink(
                    slug: Slug("floop")!,
                    title: "Floop the pig"
                )
            )
        )
    }
}
