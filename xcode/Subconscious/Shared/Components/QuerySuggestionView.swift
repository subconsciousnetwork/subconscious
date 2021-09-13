//
//  ActionSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI

//  MARK: Row View
struct QuerySuggestionView: View, Equatable {
    var suggestion: QuerySuggestion

    var body: some View {
        Label {
            HStack(spacing: 0) {
                Text(suggestion.query).foregroundColor(Constants.Color.text)
                Text(" — Create").foregroundColor(Constants.Color.secondaryText)
            }
        } icon: {
            IconView(
                image: Image(systemName: "magnifyingglass")
            ).foregroundColor(Constants.Color.accentIcon)
        }
        .lineLimit(1)
        .contentShape(Rectangle())
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

struct SuggestionRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            QuerySuggestionView(
                suggestion: QuerySuggestion(query: "Search term")
            )
            QuerySuggestionView(
                suggestion: QuerySuggestion(query: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua")
            )
        }
    }
}
