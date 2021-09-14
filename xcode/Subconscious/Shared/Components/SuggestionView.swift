//
//  SuggestionView.swift
//  SuggestionView
//
//  Created by Gordon Brander on 9/13/21.
//

import SwiftUI

struct SuggestionView: View, Equatable {
    struct QueryView: View, Equatable {
        var suggestion: QuerySuggestion

        var body: some View {
            Label {
                HStack(spacing: 0) {
                    Text(suggestion.query)
                        .foregroundColor(Constants.Color.text)
                    Text(" — Create")
                        .foregroundColor(Constants.Color.secondaryText)
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

    struct ResultView: View, Equatable {
        var suggestion: ResultSuggestion

        var body: some View {
            Label {
                HStack(spacing: 0) {
                    Text(suggestion.query)
                        .foregroundColor(Constants.Color.text)
                    Text(" — Edit")
                        .foregroundColor(Constants.Color.secondaryText)
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

    var suggestion: Suggestion

    var body: some View {
        switch suggestion {
        case .result(let result):
            ResultView(suggestion: result)
        case .query(let query):
            QueryView(suggestion: query)
        }
    }
}

struct SuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionView(
            suggestion: .result(.init(query: "Floop"))
        )
    }
}
