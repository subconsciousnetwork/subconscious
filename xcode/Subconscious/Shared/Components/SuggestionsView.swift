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
                if !store.state.suggestions.query.isWhitespace {
                    Button(action: {
                        store.send(.select(store.state.suggestions.query))
                    }) {
                        QuerySuggestionView(
                            suggestion: QuerySuggestion(
                                query: store.state.suggestions.query
                            )
                        ).equatable()
                    }.id("literalquery")
                }
                ForEach(
                    store.state.suggestions.results
                ) { suggestion in
                    Button(action: {
                        store.send(.select(suggestion.query))
                    }) {
                        ResultSuggestionView(
                            suggestion: suggestion
                        )
                        .equatable()
                    }.id("result/\(suggestion.id)")
                }
                ForEach(store.state.suggestions.queries) { suggestion in
                    Button(action: {
                        store.send(.select(suggestion.query))
                    }) {
                        QuerySuggestionView(
                            suggestion: suggestion
                        )
                        .equatable()
                    }.id("query/\(suggestion.id)")
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
                            results: [
                                ResultSuggestion(
                                    query: "If you have 70 notecards, you have a movie"
                                ),
                                ResultSuggestion(
                                    query: "Tenuki"
                                ),
                                ResultSuggestion(
                                    query: "Notecard"
                                ),
                            ],
                            queries: []
                        )
                    ),
                    send:  { query in }
                )
            )
        }
    }
}
