//
//  RenameSuggestionLabelView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

struct RenameSuggestionLabelView: View {
    var suggestion: Suggestion
    var body: some View {
        switch suggestion {
        case let .entry(stub):
            Label(
                title: {
                    TitleGroup(
                        title: stub.title.slugifyString(),
                        subtitle: "Merge ideas"
                    )
                },
                icon: {
                    Image(systemName: "arrow.triangle.merge")
                }
            ).labelStyle(SuggestionLabelStyle())
        case let .search(stub):
            Label(
                title: {
                    TitleGroup(
                        title: stub.title.slugifyString(),
                        subtitle: "Rename idea"
                    )
                },
                icon: {
                    Image(systemName: "pencil")
                }
            ).labelStyle(SuggestionLabelStyle())
        }
    }
}

struct RenameSuggestionLabel_Previews: PreviewProvider {
    static var previews: some View {
        RenameSuggestionLabelView(
            suggestion: .search(
                EntryLink(title: "Floop the pig")
            )
        )
    }
}
