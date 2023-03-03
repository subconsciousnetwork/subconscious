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
import os

//  MARK: Action
enum SearchAction: Hashable, CustomLogStringConvertible {
    /// Set search presented state
    case requestPresent(Bool)
    /// Set search presented to false, and clear query
    case hideAndClearQuery
    /// Cancel search `(proxy for isPresented(false)`)
    case cancel
    /// Set query (text in input) live as you type
    case setQuery(String)
    /// Hit submit ("go") while focused on search field
    case submitQuery(String)
    case setSuggestions([Suggestion])
    case failSuggestions(String)
    /// Refresh results by re-submitting query
    case refreshSuggestions
    /// Handle user activation of suggestion
    case activateSuggestion(Suggestion)
    /// Notify parent of suggeston activation
    case activatedSuggestion(Suggestion)
    //  Search history
    /// Write a search history event to the database
    case createSearchHistoryItem(String?)
    case succeedCreateSearchHistoryItem(String)
    case failCreateSearchHistoryItem(String)

    /// Handle notification of entry delete from somewhere
    case entryDeleted(Slug)

    var logDescription: String {
        switch self {
        case .setSuggestions(let suggestions):
            return "setSuggestions(\(suggestions.count) items)"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Model
struct SearchModel: ModelProtocol {
    var clearSearchTimeout = Duration.keyboard + 0.1

    /// Placeholder text when empty
    var placeholder = ""
    /// Live input text
    var query = ""
    var suggestions: [Identified<Suggestion>] = []

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "Search"
    )

    //  MARK: Update
    static func update(
        state: SearchModel,
        action: SearchAction,
        environment: AppEnvironment
    ) -> Update<SearchModel> {
        switch action {
        case .requestPresent:
            logger.debug("Should be handled by parent")
            return Update(state: state)
        case .hideAndClearQuery:
            return hideAndClearQuery(
                state: state,
                environment: environment
            )
        case .cancel:
            return update(
                state: state,
                action: .hideAndClearQuery,
                environment: environment
            )
        case .setQuery(let query):
            return setQuery(
                state: state,
                environment: environment,
                query: query
            )
        case .refreshSuggestions:
            return setQuery(
                state: state,
                environment: environment,
                query: state.query
            )
        case .submitQuery(let query):
            return SearchModel.update(
                state: state,
                actions: [
                    SearchAction.createSearchHistoryItem(query),
                    SearchAction.hideAndClearQuery
                ],
                environment: environment
            )
        case .setSuggestions(let suggestions):
            var model = state
            model.suggestions = suggestions.map({ suggestion in
                Identified(value: suggestion)
            })
            return Update(state: model)
        case .failSuggestions(let message):
            logger.log("\(message)")
            return Update(state: state)
        case .activateSuggestion(let suggestion):
            return activateSuggestion(
                state: state,
                environment: environment,
                suggestion: suggestion
            )
        case .activatedSuggestion:
            logger.debug(
                ".activatedSuggestion should be handled by parent component"
            )
            return Update(state: state)
        case let .createSearchHistoryItem(query):
            return createSearchHistoryItem(
                state: state,
                environment: environment,
                query: query
            )
        case let .succeedCreateSearchHistoryItem(query):
            return succeedCreateSearchHistoryItem(
                state: state,
                environment: environment,
                query: query
            )
        case let .failCreateSearchHistoryItem(error):
            return failCreateSearchHistoryItem(
                state: state,
                environment: environment,
                error: error
            )
        case .entryDeleted(_):
            // For now, we handle deletion by just refreshing suggestions.
            return update(
                state: state,
                action: .refreshSuggestions,
                environment: environment
            )
        }
    }

    /// Hide search and clear query after animation completes
    static func hideAndClearQuery(
        state: SearchModel,
        environment: AppEnvironment
    ) -> Update<SearchModel> {
        /// Delay search clearing until hide animation completes
        let delay = state.clearSearchTimeout
        let query = Just(
            SearchAction.setQuery("")
        )
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)

        let present = Just(SearchAction.requestPresent(false))

        let fx: Fx<SearchAction> = query.merge(with: present)
            .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    static func setQuery(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel> {
        let fx: Fx<SearchAction> = environment.data
            .searchSuggestions(query: query)
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
    }

    /// Handle suggestion tapped
    static func activateSuggestion(
        state: SearchModel,
        environment: AppEnvironment,
        suggestion: Suggestion
    ) -> Update<SearchModel> {
        // Duration of keyboard animation
        let duration = Duration.keyboard
        let delay = duration + 0.03

        let fx: Fx<SearchAction> = Just(
            SearchAction.activatedSuggestion(suggestion)
        )
        // Request detail AFTER hide animaiton completes
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()

        return SearchModel.update(
            state: state,
            actions: [
                .createSearchHistoryItem(suggestion.query),
                .hideAndClearQuery
            ],
            environment: environment
        )
        .mergeFx(fx)
    }

    /// Insert search history event into database
    static func createSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        query: String?
    ) -> Update<SearchModel> {
        guard let query = query else {
            return Update(state: state)
        }
        let fx: Fx<SearchAction> = environment.data
            .createSearchHistoryItem(query: query)
            .map({ query in
                SearchAction.succeedCreateSearchHistoryItem(query)
            })
            .catch({ error in
                Just(
                    SearchAction.failCreateSearchHistoryItem(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle success case for search history item creation
    static func succeedCreateSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        query: String
    ) -> Update<SearchModel> {
        logger.log(
            "Created search history entry: \(query)"
        )
        return Update(state: state)
    }

    /// Handle failure case for search history item creation
    static func failCreateSearchHistoryItem(
        state: SearchModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<SearchModel> {
        logger.log(
            "Failed to create search history entry: \(error)"
        )
        return Update(state: state)
    }
}

//  MARK: View
struct SearchView: View {
    var state: SearchModel
    var send: (SearchAction) -> Void
    var suggestionHeight: CGFloat = 56
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SearchTextField(
                    placeholder: state.placeholder,
                    text: Binding(
                        get: { state.query },
                        send: send,
                        tag: SearchAction.setQuery
                    ),
                    autofocus: true
                )
                .submitLabel(.go)
                .onSubmit {
                    send(.submitQuery(state.query))
                }
                Button(
                    action: {
                        send(.cancel)
                    },
                    label: {
                        Text("Cancel")
                    }
                )
            }
            .frame(height: AppTheme.unit * 10)
            .padding(AppTheme.tightPadding)
            List(state.suggestions) { item in
                Button(
                    action: {
                        send(.activateSuggestion(item.value))
                    },
                    label: {
                        SuggestionLabelView(suggestion: item.value)
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
            .listStyle(.plain)
        }
        .background(Color.background)
    }
    
    static var presentTransition: AnyTransition = .asymmetric(
        insertion: .opacity.animation(
            .easeOutCubic(
                duration: Duration.keyboard
            )
        ),
        removal: .opacity.animation(
            .easeOut(
                duration: Duration.keyboard / 2
            )
        )
    )
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            state: SearchModel(
                placeholder: "Search or create..."
            ),
            send: { action in }
        )
    }
}
