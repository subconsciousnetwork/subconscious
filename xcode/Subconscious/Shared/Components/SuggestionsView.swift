//
//  SuggestionListView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/8/21.
//

import SwiftUI
import Combine
import Elmo

enum SuggestionsAction {
    case selectSearch(_ query: String)
    case selectAction(_ suggestion: ActionSuggestion)
}

struct SuggestionsModel: Equatable {
    var searches: [SearchSuggestion] = []
    var actions: [ActionSuggestion] = []
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
                ForEach(store.state.searches) { suggestion in
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

            if (store.state.actions.count > 0) {
                Section(
                    header: Text("Actions")
                ) {
                    ForEach(store.state.actions) { suggestion in
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
                    ),
                    send:  { query in }
                )
            )
        }
    }
}
