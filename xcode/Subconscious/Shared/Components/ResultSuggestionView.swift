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
        Label {
            HStack(spacing: 0) {
                Text(suggestion.query).foregroundColor(Constants.Color.text)
                Text(" — Edit").foregroundColor(Constants.Color.secondaryText)
            }
        } icon: {
            IconView(
                image: Image(systemName: "doc")
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

struct SearchSuggestionView_Preview: PreviewProvider {
    static var previews: some View {
        ResultSuggestionView(
            suggestion: ResultSuggestion(query: "Query string")
        )
    }
}
