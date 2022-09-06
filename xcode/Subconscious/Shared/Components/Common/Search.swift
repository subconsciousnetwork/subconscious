//
//  Search.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/6/22.
//
//  Search HUD component.
//  - Handles fetching suggestions whenever query changes.

import SwiftUI
import Combine
import ObservableStore

//  MARK: Action
enum SearchAction: Hashable {
    case setQuery(String)
    /// Hit submit ("go") while focused on search field
    case submitQuery(String)
    case setSuggestions([Suggestion])
    case failSuggestions(String)
    case activateSuggestion(Suggestion)
    case cancel
}

//  MARK: Model
struct SearchModel: Hashable {
    var placeholder = ""
    var query = ""
    var suggestions: [Suggestion] = []

    //  MARK: Update
    static func update(
        state: SearchModel,
        action: SearchAction,
        environment: AppEnvironment
    ) -> Update<SearchModel, SearchAction> {
        switch action {
        case .setQuery(let query):
            let fx: Fx<SearchAction> = environment.database
                .searchSuggestions(
                    query: query,
                    isJournalSuggestionEnabled:
                        Config.default.journalSuggestionEnabled,
                    isScratchSuggestionEnabled:
                        Config.default.scratchSuggestionEnabled,
                    isRandomSuggestionEnabled:
                        Config.default.randomSuggestionEnabled
                )
                .map({ suggestions in
                    SearchAction.setSuggestions(suggestions)
                })
                .catch({ error in
                    Just(
                        SearchAction.failSuggestions(
                            error.localizedDescription
                        )
                    )
                })
                .eraseToAnyPublisher()

            var model = state
            model.query = query
            return Update(state: model, fx: fx)
        case .submitQuery:
            environment.logger.debug(
                ".submitQuery should be handled by parent component"
            )
            return Update(state: state)
        case .setSuggestions(let suggestions):
            var model = state
            model.suggestions = suggestions
            return Update(state: model)
        case .failSuggestions(let message):
            environment.logger.warning("\(message)")
            return Update(state: state)
        case .activateSuggestion:
            environment.logger.debug(
                ".activateSuggestion should be handled by parent component"
            )
            return Update(state: state)
        case .cancel:
            environment.logger.debug(
                ".cancel should be handled by parent component"
            )
            return Update(state: state)
        }
    }
}

//  MARK: View
struct SearchView2: View {
    var store: ViewStore<SearchModel, SearchAction>
    var suggestionHeight: CGFloat = 56

    /// Calculate maxHeight given number of suggestions.
    /// This allows us to adapt the height of the modal to the
    /// suggestions that are returned.
    private func calcMaxHeight() -> CGFloat {
        CGFloat.minimum(
            suggestionHeight * CGFloat(store.state.suggestions.count),
            suggestionHeight * 6
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SearchTextField(
                    placeholder: "Search or create...",
                    text: store.binding(
                        get: \.query,
                        tag: SearchAction.setQuery
                    ),
                    autofocus: true
                )
                .submitLabel(.go)
                .onSubmit {
                    store.send(.submitQuery(store.state.query))
                }
                Button(
                    action: {
                        store.send(.cancel)
                    },
                    label: {
                        Text("Cancel")
                    }
                )
            }
            .frame(height: AppTheme.unit * 10)
            .padding(AppTheme.tightPadding)
            List(store.state.suggestions) { suggestion in
                Button(
                    action: {
                        store.send(.activateSuggestion(suggestion))
                    },
                    label: {
                        SuggestionLabelView(suggestion: suggestion)
                    }
                )
                .modifier(
                    SuggestionViewModifier(
                        // Set suggestion height explicitly so we can
                        // rely on it for our search modal height
                        // calculations.
                        // 2022-02-17 Gordon Brander
                        height: suggestionHeight
                    )
                )
            }
            // Fix the height of the scrollview based on the number of
            // elements present.
            //
            // This allows us to shrink the modal when there are only a
            // few elements to show.
            //
            // 2022-01-28 Gordon Brander
            .frame(maxHeight: calcMaxHeight())
            .listStyle(.plain)
            .padding(.bottom, AppTheme.tightPadding)
        }
        .background(Color.background)
    }
}

struct SearchView2_Previews: PreviewProvider {
    static var previews: some View {
        SearchView2(
            store: ViewStore.constant(
                state: SearchModel()
            )
        )
    }
}
