//
//  SuggestionListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI
import Combine
import Elmo
import os

enum SuggestionsAction {
    case suggest(String)
    case suggestSuccess(Suggestions)
    case suggestFailure(message: String)
    case select(String)
}

struct SuggestionsModel: Equatable {
    var suggestions = Suggestions.Empty
}

func updateSuggestions(
    state: inout SuggestionsModel,
    action: SuggestionsAction,
    environment: IOService
) -> AnyPublisher<SuggestionsAction, Never> {
    switch action {
    case .suggest(let query):
        return environment.database.searchSuggestions(query)
            .map({ suggestions in
                .suggestSuccess(suggestions)
            })
            .catch({ error in
                Just(.suggestFailure(message: error.localizedDescription))
            })
            .eraseToAnyPublisher()
    case .suggestSuccess(let suggestions):
        state.suggestions = suggestions
    case .suggestFailure(let message):
        environment.logger.warning("\(message)")
    case .select:
        let string = String(reflecting: action)
        environment.logger.debug(
            """
            Action should be handled by parent component\t\(string)
            """
        )
    }
    return Empty().eraseToAnyPublisher()
}

//  MARK: Suggestions list view

/// A single list for ranked suggestions of multiple kinds
///
/// Deliberately does not animate row changes. This view is for type-ahead search, where these animations
/// would be distracting.
///
/// Deliberately does not handle scrolling. This is meant to be placed within a ScrollView along with other
/// types of search results.
struct SuggestionsView: View, Equatable {
    let store: ViewStore<SuggestionsModel, SuggestionsAction>

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(
                    store.state.suggestions.suggestions
                ) { suggestion in
                    Button(action: {
                        store.send(.select(suggestion.query))
                    }) {
                        SuggestionView(
                            suggestion: suggestion
                        )
                        .equatable()
                    }.id("suggestion/\(suggestion.id)")
                }
            }.listStyle(.plain)
        }
    }
}

struct Suggestions_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            SuggestionsView(
                store: ViewStore(
                    state: SuggestionsModel(
                        suggestions: Suggestions(
                            query: "",
                            suggestions: [
                                .result(.init(query: "Floop")),
                                .query(.init(query: "Pig"))
                            ]
                        )
                    ),
                    send:  { query in }
                )
            )
        }
    }
}
