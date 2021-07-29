//
//  SearchSuggestion.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/13/21.
//

import SwiftUI

struct ResultSuggestionView: View, Equatable {
    var suggestion: ResultSuggestion

    var body: some View {
        
        IconLabelRowView(
            title: suggestion.query,
            image: Image(systemName: "doc.text")
        )
        .foregroundColor(Constants.Color.text)
        .lineLimit(1)
    }
}

struct SearchSuggestionView_Preview: PreviewProvider {
    static var previews: some View {
        ResultSuggestionView(
            suggestion: ResultSuggestion(query: "Query string")
        )
    }
}
