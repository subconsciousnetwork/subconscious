//
//  SearchSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/13/21.
//

import SwiftUI

struct SearchSuggestion: Equatable, Hashable, Identifiable {
    var id: String {
        "search-suggestion/\(query.hash)"
    }
    var query: String
}

struct SearchSuggestionView: View, Equatable {
    var suggestion: SearchSuggestion

    var body: some View {
        
        IconLabelRowView(
            title: suggestion.query,
            image: Image(systemName: "magnifyingglass")
        )
        .foregroundColor(.Sub.text)
        .lineLimit(1)
    }
}

struct SearchSuggestionView_Preview: PreviewProvider {
    static var previews: some View {
        SearchSuggestionView(
            suggestion: SearchSuggestion(query: "Query string")
        )
    }
}
