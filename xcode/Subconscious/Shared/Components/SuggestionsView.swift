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
    case selectSearch(String)
    case selectAction(ActionSuggestion)
}

struct SuggestionsModel: Equatable {
    var suggestions = Suggestions()
}

struct SuggestionsService {
    var logger: Logger
    var database: DatabaseEnvironment
}

func updateSuggestions(
    state: inout SuggestionsModel,
    action: SuggestionsAction,
    environment: SuggestionsService
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
    case .selectSearch:
        break
    case .selectAction:
        break
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
        List {
            Section(
                header: Text("Search")
            ) {
                ForEach(store.state.suggestions.searches) { suggestion in
                    Button(action: {
                        store.send(.selectSearch(suggestion.query))
                    }) {
                        SearchSuggestionView(
                            suggestion: suggestion
                        )
                        .equatable()
                    }
                    .id("search/\(suggestion.id)")
                }
            }.textCase(nil)

            if (store.state.suggestions.actions.count > 0) {
                Section(
                    header: Text("Actions")
                ) {
                    ForEach(store.state.suggestions.actions) { suggestion in
                        Button(action: {
                            store.send(.selectAction(suggestion))
                        }) {
                            ActionSuggestionView(
                                suggestion: suggestion
                            )
                            .equatable()
                        }
                        .id("action/\(suggestion.id)")
                    }
                }.textCase(nil)
            }
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
                            searches: [
                                SearchSuggestion(
                                    query: "If you have 70 notecards, you have a movie"
                                ),
                                SearchSuggestion(
                                    query: "Tenuki"
                                ),
                                SearchSuggestion(
                                    query: "Notecard"
                                ),
                            ],
                            actions: []
                        )
                    ),
                    send:  { query in }
                )
            )
        }
    }
}
