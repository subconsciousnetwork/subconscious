//
//  Suggestions.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/16/21.
//

import SwiftUI

struct LinkSuggestionsView: View {
    var suggestions: [Suggestion]
    var action: (Suggestion) -> Void

    var body: some View {
        List(suggestions, id: \.self) { suggestion in
            Button(action: {
                self.action(suggestion)
            }) {
                Label(
                    title: {
                        Text(suggestion.description).lineLimit(1)
                    },
                    icon: {
                        switch suggestion {
                        case .entry:
                            Image(systemName: "doc")
                        case .search:
                            Image(systemName: "magnifyingglass")
                        }
                    }
                )
            }
        }.listStyle(.plain)
    }
}

struct LinkSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        LinkSuggestionsView(
            suggestions: [
                .search("El"),
                .entry("Elm discourages deeply nested records"),
                .entry("Elm a very long page title that should get truncated"),
                .entry("Elm app architecture"),
                .search("Elm"),
                .search("Elephant")
            ],
            action: { suggestion in }
        )
    }
}
